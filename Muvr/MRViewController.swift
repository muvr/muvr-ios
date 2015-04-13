import UIKit

class MRViewController: UIViewController, MRExerciseBlockDelegate, MRDeviceSessionDelegate {
    private let preclassification: MRPreclassification = MRPreclassification()
    private let pcd = MRRawPebbleConnectedDevice()
    
    private var payload: String = ""
    
    @IBOutlet var exercisingView: UIImageView!

    override func viewDidLoad() {
        preclassification.exerciseBlockDelegate = self
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
    
    func exerciseSessionPayload() {
        
        let a = MRPreclassification()
        a.exerciseBlockDelegate = PrintDelegate()
        
        a.pushBack(("hi" as NSString).dataUsingEncoding(NSUTF8StringEncoding), from: 1, at: CFAbsoluteTime())
        
        MuvrServer.sharedInstance.exerciseSessionPayload(ExerciseSessionPayload(data: "payloadz")) {
            $0.cata(
                {y in
                    self.payload = "boom"
                    println(self.payload)
                },
                { x in
                    self.payload = x
                    println(self.payload)
                })
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

}
