import UIKit
import Charts


class MRExerciseViewController: UIViewController, MRExerciseBlockDelegate, MRClassificationPipelineDelegate, MRDeviceSessionDelegate {
    private var preclassification: MRPreclassification?
    private let pcd = MRRawPebbleConnectedDevice()
    
    @IBOutlet var statusLabel: UILabel!
    @IBOutlet var exerciseLabel: UILabel!
    @IBOutlet var exerciseRepetitionsLabel: UILabel!
    @IBOutlet var startStopButton: UIButton!
    @IBOutlet var sensorView: MRSensorView!
    
    func startExercising(muscleGroupIds: [String]) {
        NSLog("Load classifiers here")

        // TODO: load classifiers here
        preclassification = MRPreclassification()
        preclassification!.exerciseBlockDelegate = self
        preclassification!.deviceDataDelegate = sensorView
        preclassification!.classificationPipelineDelegate = self
        pcd.start(self)
    }
    
    override func willMoveToParentViewController(parent: UIViewController?) {
        pcd.stop()
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
