import Foundation
import WatchConnectivity

///
/// The iOS counterpart of the connectivity interface
///
public final class MKConnectivity : NSObject, WCSessionDelegate {
    /// all sessions
    private(set) public var sessions: [MKExerciseConnectivitySession] = []
    /// the current session
    public var session: MKExerciseConnectivitySession? {
        return sessions.last
    }
    /// The delegate that will receive the sensor data
    public var sensorDataConnectivityDelegate: MKSensorDataConnectivityDelegate?
    /// The delegate that will receive session calls
    public var exerciseConnectivitySessionDelegate: MKExerciseConnectivitySessionDelegate?

    public override init() {
        super.init()
        // setup watch communication
        WCSession.defaultSession().delegate = self
        WCSession.defaultSession().activateSession()
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
                sessionId = userInfo["sessionId"] as? String,
                startTimestamp = userInfo["startDate"] as? Double {
                let session = MKExerciseConnectivitySession(
                    id: sessionId,
                    exerciseModelId: exerciseModelId,
                    startDate: NSDate(timeIntervalSince1970: startTimestamp)
                )
                sessions.append(session)
                if let delegate = exerciseConnectivitySessionDelegate {
                    delegate.exerciseConnectivitySessionDidStart(session: session)
                }
            }
        case .Some("end"):
            if let sessionId = userInfo["sessionId"] as? String, var last = sessions.last {
                if last.id != sessionId {
                    NSLog("last.id != sessionId. Don't know which session to end.")
                }
                last.running = false
                if let delegate = exerciseConnectivitySessionDelegate {
                    delegate.exerciseConnectivitySessionDidEnd(session: last)
                }
                sessions[sessions.count - 1] = last
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
            if let delegate = sensorDataConnectivityDelegate {
                delegate.sensorDataConnectivityDidReceiveSensorData(accumulated: last.sensorData!, new: new, session: last)
            }
            sessions[sessions.count - 1] = last
            NSLog("\(file.metadata!) with \(new.duration); now accumulated \(last.sensorData!.duration)")
        } catch {
            NSLog("\(error)")
        }
    }
    
}
