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
    MRDeviceSessionDelegate, MRDeviceDataDelegate, MRExerciseBlockDelegate, MRClassificationPipelineDelegate, MRExercisePlanDelegate {
    
    /// the timer for the stop button
    private var timer: NSTimer?
    /// the dots in the top bar
    private var pageControl: UIPageControl?
    /// the detail views that the users can flip through
    private var pageViewControllers: [UIViewController] = []
    /// session start time (for elapsed time measurement)
    private var startTime: NSDate?
    /// the preclasssification instance configured to deal with the context of the session (intensity, muscle groups, etc.)
    private var preclassification: MRPreclassification?
    /// the state to handle the results of the classification
    private var state: MRExercisingApplicationState?
    /// the plan
    private var plan: MRExercisePlan?
    /// the plan definition
    private var planDefinition: MRResistanceExercisePlan?
    /// the classification completed feedback controller
    private var classificationCompletedViewController: MRExerciseSessionClassificationCompletedViewController?
    /// are we waiting for user input?
    private var waitingForUser: Bool = false
    /// user classification
    private var userClassification: MRExerciseSessionUserClassification?
    
    // TODO: add more sensors
    /// the Pebble interface
    private let pcd = MRRawPebbleConnectedDevice()
    
    /// the stop (back) button
    @IBOutlet var stopSessionButton: UIBarButtonItem!
    /// the "add exercise button"
    @IBOutlet var explicitAddButon: UIBarButtonItem!

    /// instantiate the pages and classification-completed VC, set up page control and timer
    /// start all configured sensors
    override func viewDidLoad() {
        assert(state != nil, "state == nil: typically because startSession(...) has not been called")
        super.viewDidLoad()
        pcd.start(self)

        if let x = planDefinition {
            self.plan = MRExercisePlan(resistanceExercises: x.exercises)
            self.plan!.delegate = self
        } else {
            self.plan = MRExercisePlan.adHoc()
        }
        
        // TODO: load & configure the classifiers here (according to state & plan)
        preclassification = MRPreclassification()
        preclassification!.deviceDataDelegate = self
        preclassification!.classificationPipelineDelegate = self
        preclassification!.exerciseBlockDelegate = self

        dataSource = self
        delegate = self
        
        navigationItem.prompt = "MRExerciseSessionViewController.elapsed".localized(0, 0)
        
        let storyboard = UIStoryboard(name: "Exercise", bundle: nil)
        
        let pvc = storyboard.instantiateViewControllerWithIdentifier(MRExerciseSessionPlanViewController.storyboardId) as! MRExerciseSessionPlanViewController
        pvc.setExercisePlan(plan!)
        let dvc = storyboard.instantiateViewControllerWithIdentifier(MRExerciseSessionDeviceDataViewController.storyboardId) as! MRExerciseSessionDeviceDataViewController
        
        pageViewControllers = [pvc, dvc]
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
    }
    
    /// configures the current session
    func startSession(state: MRExercisingApplicationState, withPlan definition: MRResistanceExercisePlan?) {
        self.state = state
        self.planDefinition = definition
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
    
    @IBAction
    func explicitAdd() {
        let uc = MRExerciseSessionUserClassification(session: state!.session, data: NSData(), result: [], planned: plan!.current)
        classificationCompletedViewController?.presentClassificationResult(self, userClassification: uc, onComplete: logExerciseExample)
    }
    
    private func logExerciseExample(example: MRResistanceExerciseSetExample) {
        self.state!.postResistanceExample(example)
        if let x = example.correct {
            x.sets.forEach { self.plan!.exercise($0 as! MRResistanceExercise) }
        }
    }

    /// end the session here and on all devices
    private func end() {
        if let x = timer { x.invalidate() }
        navigationItem.prompt = nil
        pageControl?.removeFromSuperview()
        pageControl = nil

        self.state!.end(plan!.deviations as! [MRExercisePlanDeviation])
        
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
        #if (arch(i386) || arch(x86_64)) && os(iOS)
            
        plan!.noExercise()
            
        #endif
        
        if let x: MRExerciseSessionSubviewDelegate = currentPageViewController() { x.sessionUpdated() }
    }
    
    private func currentPageViewController<A>() -> A? {
        if let x = pageControl {
            return pageViewControllers[x.currentPage] as? A
        }
        return nil
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
        if waitingForUser { return }

        #if true
        
        #endif
        
        preclassification!.pushBack(data, from: 0, withHint: nil)
    }
    
    func deviceSession(session: DeviceSession, simpleMessageReceivedFrom deviceId: DeviceId, key: UInt32, value: UInt8) {
        if !waitingForUser { return }
    
        let correct = userClassification!.combinedSets[Int(value)]
        
        logExerciseExample(MRResistanceExerciseSetExample(classified: userClassification!.classifiedSets, correct: correct, fusedSensorData: userClassification!.data))
        classificationCompletedViewController?.dismissViewControllerAnimated(true, completion: nil)
        waitingForUser = false
    }
    
    // MARK: MRDeviceDataDelegate implementation
    func deviceDataDecoded1D(rows: [AnyObject]!, fromSensor sensor: UInt8, device deviceId: UInt8, andLocation location: UInt8) {
        if let x: MRDeviceDataDelegate = currentPageViewController() { x.deviceDataDecoded1D(rows, fromSensor: sensor, device: deviceId, andLocation: location) }
    }
    
    func deviceDataDecoded3D(rows: [AnyObject]!, fromSensor sensor: UInt8, device deviceId: UInt8, andLocation location: UInt8) {
        if let x: MRDeviceDataDelegate = currentPageViewController() { x.deviceDataDecoded3D(rows, fromSensor: sensor, device: deviceId, andLocation: location) }
    }
    
    // MARK: MRExerciseBlockDelegate implementation
    func exerciseEnded() {
        if waitingForUser { return }
        if let x: MRExerciseBlockDelegate = currentPageViewController() { x.exerciseEnded() }
        pcd.notifyClassifying()
    }
    
    func exercising() {
        if waitingForUser { return }
        if let x: MRExerciseBlockDelegate = currentPageViewController() { x.exercising() }
        if let x: MRExerciseSessionSubviewDelegate = currentPageViewController() { x.sessionUpdated() }
        pcd.notifyExercising()
    }
    
    func moving() {
        if waitingForUser { return }
        if let x: MRExerciseBlockDelegate = currentPageViewController() { x.moving() }
        if let x: MRExerciseSessionSubviewDelegate = currentPageViewController() { x.sessionUpdated() }
        pcd.notifyMoving()
    }
    
    func notMoving() {
        if waitingForUser { return }

        plan!.noExercise();
        
        if let x: MRExerciseBlockDelegate = currentPageViewController() { x.notMoving() }
        if let x: MRExerciseSessionSubviewDelegate = currentPageViewController() { x.sessionUpdated() }
        pcd.notifyNotMoving()
    }
    
    // MARK: MRClassificationPipelineDelegate
    func classificationCompleted(result: [AnyObject]!, fromData data: NSData!) {
        if waitingForUser { return }
        
        waitingForUser = true

        userClassification = MRExerciseSessionUserClassification(session: state!.session, data: data, result: [], planned: plan!.current)
        assert(!userClassification!.combinedSimpleSets.isEmpty, "Attempt to present classification result with no options.")
        
        classificationCompletedViewController?.presentClassificationResult(self, userClassification: userClassification!, onComplete: logExerciseExample)
        pcd.notifySimpleClassificationCompleted(userClassification!.combinedSimpleSets)
    }
    
    // MARK: MRExercisePlanDelegate
    func currentItem(item: MRExercisePlanItem!, changedFromPrevious previous: MRExercisePlanItem!) {
        if let re = item.resistanceExercise {
            pcd.notifySimpleCurrent(re)
        }
    }
    
}
