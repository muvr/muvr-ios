import Foundation
import WatchConnectivity

///
/// The iOS counterpart of the connectivity interface
///
public final class MKConnectivity : NSObject, WCSessionDelegate {
    private(set) public var sessions: [MKExerciseConnectivitySession] = []
    public var session: MKExerciseConnectivitySession? {
        return sessions.last
    }
    /// The delegate that will receive the sensor data
    private var sensorDataConnectivityDelegate: (MKSensorDataConnectivityDelegate, dispatch_queue_t)?
    private var exerciseConnectivitySessionDelegate: (MKExerciseConnectivitySessionDelegate, dispatch_queue_t)?

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
    public func setExerciseConnectivitySessionDelegate(delegate delegate: MKExerciseConnectivitySessionDelegate, on queue: dispatch_queue_t) {
        self.exerciseConnectivitySessionDelegate = (delegate, queue)
    }
    
    ///
    /// Clears the currently-running session
    ///
    public func clear() {
        sessions = []
    }
    
    public func session(session: WCSession, didReceiveUserInfo userInfo: [String : AnyObject]) {
        switch userInfo["action"] as? String {
        case .Some("start"):
            if let exerciseModelId = userInfo["exerciseModelId"] as? MKExerciseModelId,
                sessionId = userInfo["sessionId"] as? String {
                    
                if let (delegate, queue) = exerciseConnectivitySessionDelegate {
                    dispatch_async(queue) {
                        delegate.exerciseConnectivitySessionDidStart(sessionId: sessionId, exerciseModelId: exerciseModelId)
                    }
                }
                sessions.append(MKExerciseConnectivitySession(id: sessionId))
            }
        case .Some("end"):
            if let sessionId = userInfo["sessionId"] as? String {
                if let (delegate, queue) = exerciseConnectivitySessionDelegate {
                    dispatch_async(queue) {
                        delegate.exerciseConnectivitySessionDidEnd(sessionId: sessionId)
                    }
                }
                if var last = sessions.last {
                    if last.id == sessionId {
                        last.running = false
                    }
                    sessions[sessions.count - 1] = last
                }
            }
        default:
            NSLog("Unknown action in \(userInfo)")
        }
    }
    
    public func session(session: WCSession, didReceiveFile file: WCSessionFile) {
        guard var last = sessions.last else { return }
        
        if let metadata = file.metadata, timestamp = metadata["timestamp"] as? NSTimeInterval {
            if last.sensorDataFileTimestamps.contains(timestamp) {
                NSLog("Received duplicate timestamp file. Ignoring")
                return
            }
            last.sensorDataFileTimestamps.insert(timestamp)
        }
        
        let documentsUrl = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.CachesDirectory, NSSearchPathDomainMask.UserDomainMask, true).first!
        let timestamp = String(NSDate().timeIntervalSince1970)
        let fileUrl = NSURL(fileURLWithPath: documentsUrl).URLByAppendingPathComponent("sensordata-\(timestamp).raw")
        last.sensorDataFiles.append(fileUrl)
        
        do {
            try NSFileManager.defaultManager().moveItemAtURL(file.fileURL, toURL: fileUrl)
            let data = NSData(contentsOfURL: fileUrl)!
            let new = try MKSensorData(decoding: data)
            if last.sensorData != nil {
                try last.sensorData!.append(new)
            } else {
                last.sensorData = new
            }
            if let (delegate, queue) = sensorDataConnectivityDelegate {
                dispatch_async(queue) {
                    delegate.sensorDataConnectivityDidReceiveSensorData(accumulated: last.sensorData!, new: new)
                }
            }
            sessions[sessions.count - 1] = last
            NSLog("\(file.metadata!) with \(new.duration); now accumulated \(last.sensorData!.duration)")
        } catch {
            NSLog("\(error)")
        }
    }
    
}
