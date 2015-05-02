import Foundation

///
/// Controls paged set of views that together form the view of the current exercise session. At the start,
/// it configures the classifier (and all its inner components), then connects the configured devices.
///
/// As the data from the devices arrive, it is pushed to the ``MRPreclassification`` instance, which in turn
/// triggers other delegate methods.
///
/// This controller only really cares about the device and classification delegate calls. The other delegates
/// used in ``MRPreclassification`` are implemented as proxies to the view controllers that handle the various
/// pages.
///
class MRExerciseSessionViewController : UIPageViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate,
    MRDeviceSessionDelegate, MRDeviceDataDelegate, MRExerciseBlockDelegate, MRClassificationPipelineDelegate {
    
    /// the timer for the stop button
    private var timer: NSTimer?
    /// the dots in the top bar
    private var pageControl: UIPageControl?
    /// the detail views that the users can flip through
    private var pageViewControllers: [UIViewController] = []
    /// the classification completed feedback controller
    private var classificationCompletedViewController: MRExerciseSessionClassificationCompletedViewController?
    /// session start time (for elapsed time measurement)
    private var startTime: NSDate?
    /// the preclasssification instance configured to deal with the context of the session (intensity, muscle groups, etc.)
    private var preclassification: MRPreclassification?
    /// the state to handle the results of the classification
    private var state: MRExercisingApplicationState?
    
    // TODO: add more sensors
    /// the Pebble interface
    private let pcd = MRRawPebbleConnectedDevice()
    
    /// the stop (back) button
    @IBOutlet var stopSessionButton: UIBarButtonItem!

    /// instantiate the pages and classification-completed VC, set up page control and timer
    /// start all configured sensors
    override func viewDidLoad() {
        assert(preclassification != nil, "preclassification == nil: typically because startSession(...) has not been called")
        assert(state != nil, "state == nil: typically because startSession(...) has not been called")
        
        super.viewDidLoad()
        dataSource = self
        delegate = self
        
        navigationItem.prompt = "MRExerciseSessionViewController.elapsed".localized(0, 0)
        
        let storyboard = UIStoryboard(name: "Exercise", bundle: nil)
        pageViewControllers = [MRExerciseSessionDeviceDataViewController.storyboardId, MRExerciseSessionLogViewController.storyboardId].map { storyboard.instantiateViewControllerWithIdentifier($0) as! UIViewController }
        classificationCompletedViewController = storyboard.instantiateViewControllerWithIdentifier(MRExerciseSessionClassificationCompletedViewController.storyboardId) as? MRExerciseSessionClassificationCompletedViewController
        
        setViewControllers([pageViewControllers.first!], direction: UIPageViewControllerNavigationDirection.Forward, animated: false, completion: nil)
        
        if let nc = navigationController {
            let navBarSize = nc.navigationBar.bounds.size
            let origin = CGPoint(x: navBarSize.width / 2, y: navBarSize.height / 2 + navBarSize.height / 4)
            pageControl = UIPageControl(frame: CGRect(x: origin.x, y: origin.y, width: 0, height: 0))
            pageControl!.numberOfPages = pageViewControllers.count
            pageControl!.autoresizingMask = UIViewAutoresizing.FlexibleLeftMargin | UIViewAutoresizing.FlexibleRightMargin
            nc.navigationBar.addSubview(pageControl!)
        }
        
        startTime = NSDate()
        timer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: "tick", userInfo: nil, repeats: true)
        
        pcd.start(self)
    }
    
    /// configures the current session
    func startSession(state: MRExercisingApplicationState) {
        self.state = state
        
        // TODO: load & configure the classifiers here
        preclassification = MRPreclassification()
        preclassification!.deviceDataDelegate = self
        preclassification!.classificationPipelineDelegate = self
        preclassification!.exerciseBlockDelegate = self
    }
    
    @IBAction
    func stopSession() {
        if stopSessionButton.tag < 0 {
            stopSessionButton.title = "Really?".localized()
            stopSessionButton.tag = 3
        } else {
            end()
        }
    }

    /// end the session here and on all devices
    func end() {
        if let x = timer { x.invalidate() }
        navigationItem.prompt = nil
        pageControl?.removeFromSuperview()
        pageControl = nil

        pcd.stop()
        navigationController?.popToRootViewControllerAnimated(true)
    }
    
    /// timer tick callback
    func tick() {
        let elapsed = Int(NSDate().timeIntervalSinceDate(startTime!))
        let minutes: Int = elapsed / 60
        let seconds: Int = elapsed - minutes * 60
        navigationItem.prompt = "MRExerciseSessionViewController.elapsed".localized(minutes, seconds)
        stopSessionButton.tag -= 1
        if stopSessionButton.tag < 0 {
            stopSessionButton.title = "Stop".localized()
        }
    }
    
    // MARK: UIPageViewControllerDataSource
    func pageViewController(pageViewController: UIPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {
        if let x = (pageViewControllers.indexOf { $0 === viewController }) {
            if x < pageViewControllers.count - 1 { return pageViewControllers[x + 1] }
        }
        return nil
    }
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController? {
        if let x = (pageViewControllers.indexOf { $0 === viewController }) {
            if x > 0 { return pageViewControllers[x - 1] }
        }
        return nil
    }
    
    // MARK: UIPageViewControllerDelegate
    func pageViewController(pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [AnyObject], transitionCompleted completed: Bool) {
        if let x = (pageViewControllers.indexOf { $0 === pageViewController.viewControllers.first! }) {
            pageControl?.currentPage = x
        }
    }
        
    // MARK: MRDeviceSessionDelegate implementation
    func deviceSession(session: DeviceSession, endedFrom deviceId: DeviceId) {
        end()
    }
    
    func deviceSession(session: DeviceSession, sensorDataNotReceivedFrom deviceId: DeviceId) {
    }
    
    func deviceSession(session: DeviceSession, sensorDataReceivedFrom deviceId: DeviceId, atDeviceTime time: CFAbsoluteTime, data: NSData) {
        //NSLog("%@", data)
        preclassification!.pushBack(data, from: 0)
    }
    
    // MARK: MRDeviceDataDelegate implementation
    func deviceDataDecoded1D(rows: [AnyObject]!, fromSensor sensor: UInt8, device deviceId: UInt8, andLocation location: UInt8) {
        if let x = pageViewControllers[pageControl!.currentPage] as? MRDeviceDataDelegate { x.deviceDataDecoded1D(rows, fromSensor: sensor, device: deviceId, andLocation: location) }
    }
    
    func deviceDataDecoded3D(rows: [AnyObject]!, fromSensor sensor: UInt8, device deviceId: UInt8, andLocation location: UInt8) {
        if let x = pageViewControllers[pageControl!.currentPage] as? MRDeviceDataDelegate { x.deviceDataDecoded3D(rows, fromSensor: sensor, device: deviceId, andLocation: location) }
    }
    
    // MARK: MRExerciseBlockDelegate implementation
    func exerciseEnded() {
        if let x = pageViewControllers[pageControl!.currentPage] as? MRExerciseBlockDelegate { x.exerciseEnded() }
    }
    
    func exercising() {
        if let x = pageViewControllers[pageControl!.currentPage] as? MRExerciseBlockDelegate { x.exercising() }
    }
    
    func moving() {
        if let x = pageViewControllers[pageControl!.currentPage] as? MRExerciseBlockDelegate { x.moving() }
    }
    
    func notMoving() {
        if let x = pageViewControllers[pageControl!.currentPage] as? MRExerciseBlockDelegate { x.notMoving() }
    }
    
    // MARK: MRClassificationPipelineDelegate
    func classificationCompleted(result: [AnyObject]!, fromData data: NSData!) {
        classificationCompletedViewController?.presentClassificationResult(self, state: state!, result: result, fromData: data)
    }
    
}
