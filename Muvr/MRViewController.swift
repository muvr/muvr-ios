import UIKit

class MRViewController: UIViewController, MRExerciseBlockDelegate, MRClassificationPipelineDelegate, MRDeviceSessionDelegate {
    private let preclassification: MRPreclassification = MRPreclassification()
    private let pcd = MRRawPebbleConnectedDevice()
    
    @IBOutlet var exercisingView: UIImageView!

    override func viewDidLoad() {
        preclassification.exerciseBlockDelegate = self
        preclassification.classificationPipelineDelegate = self
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        exercisingView.hidden = true
    }
    
    @IBAction
    func start() {
        pcd.start(self)
    }
    
    @IBAction
    func stop() {
        pcd.stop()
    }
    
    @IBAction
    func send() {
        exerciseSessionPayload()
    }
    
    // TODO: Send correct fused / preprocessed sensor data
    func exerciseSessionPayload() {
        MRMuvrServer.sharedInstance.exerciseSessionPayload(MRExerciseSessionPayload(data: "payloadz")) {
            $0.cata(
                { e in println("Server request failed: " + e.localizedDescription) },
                r: { s in println("Server request success: " + s) })
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
        NSLog("%@", data)
        //preclassification.pushBack(data, from: 0, at: time)
    }
    
    // MARK: MRExerciseBlockDelegate implementation
    
    func exerciseBlockEnded() {
        exercisingView.hidden = true
    }
    
    func exerciseBlockStarted() {
        exercisingView.hidden = false
    }
    
    // MARK: MRClassificationDelegate
    func classificationSucceeded() {//(exercise: String!, fromData data: NSData!) {
        println("Successfully classified exercise")
        // Positive sample: MuvrServer.sharedInstance...
    }
    
    func classificationAmbiguous() { //(exercises: [AnyObject]!, fromData data: NSData!) {
        println("Ambiguously classified exercise")
        // BT message to the watch -> decide
        // Positive sample: MuvrServer.sharedInstance...
    }
    
    func classificationFailed() { //(data: NSData!) {
        println("Failed to classify exercise")
        // Failning sample: MuvrServer.sharedInstance...
    }

}
