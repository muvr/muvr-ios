import UIKit
import Charts


class MRExerciseViewController: UIViewController, MRExerciseBlockDelegate, MRClassificationPipelineDelegate, MRDeviceSessionDelegate {
    private let preclassification: MRPreclassification = MRPreclassification()
    private let pcd = MRRawPebbleConnectedDevice()
    
    @IBOutlet var statusLabel: UILabel!
    @IBOutlet var exerciseLabel: UILabel!
    @IBOutlet var exerciseRepetitionsLabel: UILabel!
    @IBOutlet var startStopButton: UIButton!
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
    func startStop() {
        if pcd.running {
            startStopButton.setTitle("Start", forState: UIControlState.Normal)
            startStopButton.titleLabel?.text = "Start"
            pcd.stop()
            statusLabel.text = "---";
        } else {
            startStopButton.setTitle("Stop", forState: UIControlState.Normal)
            statusLabel.text = "Starting...";
            pcd.start(self)
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
    
    func classificationCompleted(result: [AnyObject]!, fromData data: NSData!) {
        MRClassificationCompletedViewController.presentClassificationResult(self, result: result, fromData: data)
    }
}
