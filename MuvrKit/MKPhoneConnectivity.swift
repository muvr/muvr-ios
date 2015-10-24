import Foundation
import WatchConnectivity

///
/// The iOS counterpart of the connectivity interface
///
public final class MKConnectivity : NSObject, WCSessionDelegate {
    /// all sessions
    private(set) public var sessions: [MKExerciseConnectivitySession] = []
    /// The delegate that will receive the sensor data
    public let sensorDataConnectivityDelegate: MKSensorDataConnectivityDelegate
    /// The delegate that will receive session calls
    public let exerciseConnectivitySessionDelegate: MKExerciseConnectivitySessionDelegate

    public init(sensorDataConnectivityDelegate: MKSensorDataConnectivityDelegate, exerciseConnectivitySessionDelegate: MKExerciseConnectivitySessionDelegate) {
        self.sensorDataConnectivityDelegate = sensorDataConnectivityDelegate
        self.exerciseConnectivitySessionDelegate = exerciseConnectivitySessionDelegate
            
        super.init()
        // setup watch communication
        WCSession.defaultSession().delegate = self
        WCSession.defaultSession().activateSession()
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
                exerciseConnectivitySessionDelegate.exerciseConnectivitySessionDidStart(session: session)
            }
        case .Some("end"):
            if let sessionId = userInfo["sessionId"] as? String, index = (sessions.indexOf { $0.id == sessionId }) {
                let session = sessions[index]
                sessions.removeAtIndex(index)
                exerciseConnectivitySessionDelegate.exerciseConnectivitySessionDidEnd(session: session)
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
        
        do {
            try NSFileManager.defaultManager().moveItemAtURL(file.fileURL, toURL: fileUrl)
            let data = NSData(contentsOfURL: fileUrl)!
            let new = try MKSensorData(decoding: data)
            if last.sensorData != nil {
                try last.sensorData!.append(new)
            } else {
                last.sensorData = new
            }
            sensorDataConnectivityDelegate.sensorDataConnectivityDidReceiveSensorData(accumulated: last.sensorData!, new: new, session: last)
            sessions[sessions.count - 1] = last
            NSLog("\(file.metadata!) with \(new.duration); now accumulated \(last.sensorData!.duration)")
        } catch {
            NSLog("\(error)")
        }
    }
    
}
