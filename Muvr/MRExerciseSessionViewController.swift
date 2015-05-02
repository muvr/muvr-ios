import Foundation

class MRExerciseSessionViewController : UIPageViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate,
    MRDeviceSessionDelegate, MRDeviceDataDelegate, MRClassificationPipelineDelegate {
    
    private var timer: NSTimer?
    private var pageControl: UIPageControl!
    private var pageViewControllers: [UIViewController] = []
    private var classificationCompletedViewController: MRClassificationCompletedViewController!
    private var startTime: NSDate?
    private var preclassification: MRPreclassification?
    private var state: MRExercisingApplicationState!
    
    // TODO: add more sensors
    private let pcd = MRRawPebbleConnectedDevice()
    
    @IBOutlet var stopSessionButton: UIBarButtonItem!

    override func viewWillDisappear(animated: Bool) {
        if let x = timer { x.invalidate() }
        navigationItem.prompt = nil
        pageControl.removeFromSuperview()
        pageControl = nil
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        dataSource = self
        delegate = self
        
        let storyboard = UIStoryboard(name: "Exercise", bundle: nil)
        pageViewControllers = [MRExerciseSessionDeviceDataViewController.storyboardId, MRExerciseSessionLogViewController.storyboardId].map { storyboard.instantiateViewControllerWithIdentifier($0) as! UIViewController }
        classificationCompletedViewController = storyboard.instantiateViewControllerWithIdentifier(MRClassificationCompletedViewController.storyboardId) as! MRClassificationCompletedViewController
        
        setViewControllers([pageViewControllers.first!], direction: UIPageViewControllerNavigationDirection.Forward, animated: false, completion: nil)
        
        if let nc = navigationController {
            let navBarSize = nc.navigationBar.bounds.size
            let origin = CGPoint(x: navBarSize.width / 2, y: navBarSize.height / 2 + navBarSize.height / 4)
            pageControl = UIPageControl(frame: CGRect(x: origin.x, y: origin.y, width: 0, height: 0))
            pageControl.numberOfPages = 3
            nc.navigationBar.addSubview(pageControl)
        }
        
        startTime = NSDate()
        timer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: "tick", userInfo: nil, repeats: true)
        
        pcd.start(self)
    }
    
    func startSession(state: MRExercisingApplicationState) {
        self.state = state
        
        // TODO: load & configure the classifiers here
        preclassification = MRPreclassification()
    }
    
    @IBAction
    func stopSession() {
        if stopSessionButton.tag < 0 {
            stopSessionButton.title = "Really?".localized()
            stopSessionButton.tag = 3
        } else {
            pcd.stop()
            navigationController?.popToRootViewControllerAnimated(true)
        }
    }
    
    func tick() {
        let elapsed = Int(NSDate().timeIntervalSinceDate(startTime!))
        let minutes: Int = elapsed / 60
        let seconds: Int = elapsed - minutes * 60
        navigationItem.prompt = "LiveSessionController.elapsed".localized(minutes, seconds)
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
            pageControl.currentPage = x
        }

        // set the delegates
        if let x = pageViewController.viewControllers.first as? UIViewController {
            if let d = x as? MRExerciseBlockDelegate { preclassification!.exerciseBlockDelegate = d }
            if let d = x as? MRClassificationPipelineDelegate { preclassification!.classificationPipelineDelegate = d }
            if let d = x as? MRDeviceDataDelegate { preclassification!.deviceDataDelegate = d }
        }
    }
    
    // MARK: MRDeviceSessionDelegate implementation
    func deviceSession(session: DeviceSession, endedFrom deviceId: DeviceId) {
        //
    }
    
    func deviceSession(session: DeviceSession, sensorDataNotReceivedFrom deviceId: DeviceId) {
        //
    }
    
    func deviceSession(session: DeviceSession, sensorDataReceivedFrom deviceId: DeviceId, atDeviceTime time: CFAbsoluteTime, data: NSData) {
        //NSLog("%@", data)
        preclassification!.pushBack(data, from: 0)
    }
    
    // MARK: MRDeviceDataDelegate implementation
    func deviceDataDecoded1D(rows: [AnyObject]!, fromSensor sensor: UInt8, device deviceId: UInt8, andLocation location: UInt8) {
        
    }
    
    func deviceDataDecoded3D(rows: [AnyObject]!, fromSensor sensor: UInt8, device deviceId: UInt8, andLocation location: UInt8) {
        
    }
    
    // MARK: MRExerciseBlockDelegate implementation
    func exerciseEnded() {
        
    }
    
    func exercising() {
        
    }
    
    func moving() {
        
    }
    
    func notMoving() {
        
    }
    
    // MARK: MRClassificationPipelineDelegate
    func classificationCompleted(result: [AnyObject]!, fromData data: NSData!) {
        classificationCompletedViewController.presentClassificationResult(self, state: state, result: result, fromData: data)
    }
    
}