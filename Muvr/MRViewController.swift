import UIKit
import Charts

class MRViewController: UIViewController, MRExerciseBlockDelegate, MRClassificationPipelineDelegate, MRDeviceSessionDelegate {
    private let preclassification: MRPreclassification = MRPreclassification()
    private let pcd = MRRawPebbleConnectedDevice()
    
    @IBOutlet var statusLabel: UILabel!
    @IBOutlet var sensorView: MRSensorView!

    override func viewDidLoad() {
        preclassification.exerciseBlockDelegate = self
        preclassification.deviceDataDelegate = sensorView
        preclassification.classificationPipelineDelegate = self
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        statusLabel.text = "---";
    }
    
    @IBAction
    func start() {
        statusLabel.text = "Starting...";
        pcd.start(self)
    }
    
    @IBAction
    func stop() {
        pcd.stop()
        statusLabel.text = "---";
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
        //NSLog("%@", data)
        preclassification.pushBack(data, from: 0)
    }
    
    // MARK: MRExerciseBlockDelegate implementation
    
    func exerciseEnded() {
        statusLabel.text = "Exercise ended";
    }
    
    func exercising() {
        statusLabel.text = "Exercising";
    }
    
    func moving() {
        statusLabel.text = "Moving";
    }
    
    func notMoving() {
        statusLabel.text = "Not moving";
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
