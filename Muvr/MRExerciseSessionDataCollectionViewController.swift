import Foundation

class MRExerciseSessionDataCollectionViewController : UIViewController, MRExerciseSessionStartable, MRDeviceSessionDelegate, MRDeviceDataDelegate,
    MRExerciseBlockDelegate {
    @IBOutlet var sensorView: MRSensorView!
    @IBOutlet var stopSessionButton: UIBarItem!
    @IBOutlet var markButton: UIBarButtonItem!
    @IBOutlet var stateLabel: UILabel!
    private var state: MRExercisingApplicationState?
    private let pcd = MRRawPebbleConnectedDevice()
    private var preclassification: MRPreclassification?
    private var timer: NSTimer?
    private var counter: Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        preclassification = MRPreclassification()
        preclassification!.deviceDataDelegate = self
        preclassification!.exerciseBlockDelegate = self
        navigationItem.prompt = "---"

        pcd.start(self)

        timer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: "tick", userInfo: nil, repeats: true)
        
        UIApplication.sharedApplication().idleTimerDisabled = true
    }
    
    private func end() {
        UIApplication.sharedApplication().idleTimerDisabled = false
        
        timer?.invalidate()
        navigationItem.prompt = nil
        pcd.stop()
        navigationController?.popToRootViewControllerAnimated(true)
    }
    
    func tick() {
        stopSessionButton.tag -= 1
        if stopSessionButton.tag < 0 {
            stopSessionButton.title = "Stop".localized()
        }
    }

    /// configures the current session
    func startSession(state: MRExercisingApplicationState, withPlan definition: MRResistanceExercisePlan?) {
        self.state = state
    }
    
    @IBAction func endSession() {
        if stopSessionButton.tag < 0 {
            stopSessionButton.title = "Really?".localized()
            stopSessionButton.tag = 3
        } else {
            end()
        }
    }
    
    @IBAction func mark() {
        if markButton.tag == 0 {
            // Unmarked -> Marked
            counter += 1
            markButton.title = "End"
            navigationItem.prompt = "Mark \(counter)"
            markButton.tag = 1
        } else {
            // Marked -> Unmarked
            markButton.title = "Collect"
            navigationItem.prompt = "---"
            markButton.tag = 0
        }
    }
    
    // MARK: MRDeviceSessionDelegate implementation
    func deviceSession(session: DeviceSession, endedFrom deviceId: DeviceId) {
    }
    
    func deviceSession(session: DeviceSession, sensorDataNotReceivedFrom deviceId: DeviceId) {
    }
    
    func deviceSession(session: DeviceSession, sensorDataReceivedFrom deviceId: DeviceId, atDeviceTime time: CFAbsoluteTime, data: NSData) {
        preclassification!.pushBack(data, from: 0, withHint: nil)
        
        if markButton.tag != 0 {
            state!.collectData(mark: counter, deviceId: deviceId, atDeviceTime: time, data: data)
        }
    }
    
    func deviceSession(session: DeviceSession, simpleMessageReceivedFrom deviceId: DeviceId, key: UInt32, value: UInt8) {
        
    }
    
    // MARK: MRExerciseBlockDelegate
    func exerciseEnded() {
        stateLabel.text = "exercise ended"
    }
    
    func exercising() {
        stateLabel.text = "exercising"
    }
    
    func moving() {
        stateLabel.text = "moving"
    }
    
    func notMoving() {
        stateLabel.text = "not moving"
    }
    
    // MARK: MRDeviceDataDelegate implementation
    func deviceDataDecoded1D(rows: [AnyObject]!, fromSensor sensor: UInt8, device deviceId: UInt8, andLocation location: UInt8) {
        sensorView.deviceDataDecoded1D(rows, fromSensor: sensor, device: deviceId, andLocation: location)
    }
    
    func deviceDataDecoded3D(rows: [AnyObject]!, fromSensor sensor: UInt8, device deviceId: UInt8, andLocation location: UInt8) {
        sensorView.deviceDataDecoded3D(rows, fromSensor: sensor, device: deviceId, andLocation: location)
    }
}