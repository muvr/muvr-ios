import Foundation
import WatchConnectivity

///
/// The iOS counterpart of the connectivity interface
///
public final class MKConnectivity : NSObject, WCSessionDelegate {
    /// accumulated sensor data
    private var sensorData: MKSensorData?
    /// batch session files
    private var sensorDataFiles: [NSURL] = []
    private var sensorDataFileTimestamps = Set<NSTimeInterval>()
    
    /// The delegate that will receive the sensor data
    private var sensorDataConnectivityDelegate: (MKSensorDataConnectivityDelegate, dispatch_queue_t)?
    private var exerciseSessionDelegate: (MKExerciseSessionDelegate, dispatch_queue_t)?

    public override init() {
        super.init()
        // setup watch communication
        WCSession.defaultSession().delegate = self
        WCSession.defaultSession().activateSession()
    }
    
    ///
    /// Sets the delegate that will...
    ///
    public func setDataConnectivityDelegate(delegate delegate: MKSensorDataConnectivityDelegate, on queue: dispatch_queue_t) {
        self.sensorDataConnectivityDelegate = (delegate, queue)
    }
    
    ///
    /// XXX
    ///
    public func setExerciseSessionDelegate(delegate delegate: MKExerciseSessionDelegate, on queue: dispatch_queue_t) {
        self.exerciseSessionDelegate = (delegate, queue)
    }
    
    ///
    /// Clears the currently-running session
    ///
    public func clear() {
        sensorData = nil
        sensorDataFileTimestamps = Set<NSTimeInterval>()
        sensorDataFiles = []
    }
    
    ///
    /// Returns the array of ``NSURL``s with the session files
    ///
    public func getSensorDataFiles() -> [NSURL] {
        return sensorDataFiles
    }
    
    public func session(session: WCSession, didReceiveUserInfo userInfo: [String : AnyObject]) {
        switch userInfo["action"] as? String {
        case .Some("start"):
            if let exerciseModelId = userInfo["exerciseModelId"] as? MKExerciseModelId,
                   sessionId = userInfo["sessionId"] as? String,
                   (delegate, queue) = exerciseSessionDelegate {
                dispatch_async(queue) {
                    delegate.exerciseSessionDidStart(sessionId: sessionId, exerciseModelId: exerciseModelId)
                }
            }
        case .Some("end"):
            if let sessionId = userInfo["sessionId"] as? String,
                   (delegate, queue) = exerciseSessionDelegate {
                dispatch_async(queue) {
                    delegate.exerciseSessionDidEnd(sessionId: sessionId)
                }
            }
        default:
            NSLog("Unknown action in \(userInfo)")
        }
    }
    
    public func session(session: WCSession, didReceiveFile file: WCSessionFile) {
        if let metadata = file.metadata, timestamp = metadata["timestamp"] as? NSTimeInterval {
            if sensorDataFileTimestamps.contains(timestamp) {
                NSLog("Received duplicate timestamp file. Ignoring")
                return
            }
            sensorDataFileTimestamps.insert(timestamp)
        }
        
        let documentsUrl = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.CachesDirectory, NSSearchPathDomainMask.UserDomainMask, true).first!
        let timestamp = String(NSDate().timeIntervalSince1970)
        let fileUrl = NSURL(fileURLWithPath: documentsUrl).URLByAppendingPathComponent("sensordata-\(timestamp).raw")
        sensorDataFiles.append(fileUrl)
        
        do {
            try NSFileManager.defaultManager().moveItemAtURL(file.fileURL, toURL: fileUrl)
            let data = NSData(contentsOfURL: fileUrl)!
            let new = try MKSensorData(decoding: data)
            if sensorData != nil {
                try sensorData!.append(new)
            } else {
                sensorData = new
            }
            if let (delegate, queue) = sensorDataConnectivityDelegate {
                dispatch_async(queue) {
                    delegate.sensorDataConnectivityDidReceiveSensorData(accumulated: self.sensorData!, new: new)
                }
            }
            NSLog("\(file.metadata!) with \(new.duration); now accumulated \(sensorData!.duration)")
        } catch {
            NSLog("\(error)")
        }
    }
    
//    public func session(session: WCSession, didReceiveMessageData messageData: NSData, replyHandler: (NSData) -> Void) {
//        do {
//            replyHandler("Ack".dataUsingEncoding(NSASCIIStringEncoding)!)
//            
//            let blockSensorData = try MKSensorData(decoding: messageData)
//            if sensorData != nil {
//                try sensorData!.append(blockSensorData)
//            } else {
//                sensorData = blockSensorData
//            }
//            
//            let classified = try classifier.classify(block: sensorData!, maxResults: 5)
//            dispatch_async(dispatch_get_main_queue(), {
//                self.log.text = self.log.text + "\n~> \(self.sensorData!.duration): \(classified.first)"
//            })
//        } catch {
//            dispatch_async(dispatch_get_main_queue(), {
//                self.log.text = self.log.text + "\n\(error)"
//            })
//        }
//    }
//    
//    func session(session: WCSession, didReceiveMessage message: [String : AnyObject], replyHandler: ([String : AnyObject]) -> Void) {
//        replyHandler(["ack" : "bar"])
//        
//        switch (message["action"] as? String) ?? "" {
//        case "begin-real-time":
//            dispatch_async(dispatch_get_main_queue(), {
//                self.log.text = self.log.text + "\nBegin RT"
//            })
//            
//            return
//        case "end-real-time":
//            dispatch_async(dispatch_get_main_queue(), {
//                self.log.text = self.log.text + "\nEnd RT"
//            })
//            sensorData = nil
//        default:
//            return
//        }
//    }

}
