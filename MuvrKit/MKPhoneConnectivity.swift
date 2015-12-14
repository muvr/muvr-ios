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
        
    ///
    /// Get the correct session instance (and its index) based on the received metadata
    /// Issues corresponding session start/end events
    ///
    private func resolveSession(metadata: [String:AnyObject]) -> (MKExerciseConnectivitySession, Int)? {
        guard let session = MKExerciseConnectivitySession.fromMetadata(metadata) else { return nil }
        let index = sessions.indexOf { $0.id == session.id } ?? sessions.count
        if (index == sessions.count) {
            // first time we see this session
            sessions.append(session)
            // issue a session start
            exerciseConnectivitySessionDelegate.exerciseConnectivitySessionDidStart(session: session)
            if (session.end != nil) {
                // issue a session end too because this session is already over
                exerciseConnectivitySessionDelegate.exerciseConnectivitySessionDidStart(session: session)
            }
        }
        sessions[index].last = session.last
        if sessions[index].end == nil && session.end != nil {
            // update the existing session with the received end timestamp
            sessions[index].end = session.end
            // issue a session end
            exerciseConnectivitySessionDelegate.exerciseConnectivitySessionDidEnd(session: session)
        }
        return (sessions[index], index)
    }
      
    public func session(session: WCSession, didReceiveUserInfo userInfo: [String : AnyObject]) {
        resolveSession(userInfo)
    }
    
    public func session(session: WCSession, didReceiveFile file: WCSessionFile) {
        // we must have metadata
        guard let metadata = file.metadata else {
            NSLog("Missing metadata in \(file)")
            return
        }
        
        // the metadata must be convertible to a session
        guard let (cs, index) = resolveSession(metadata) else { return }
        var connectivitySession = cs

        // check for duplicate transmissions
        if let timestamp = metadata["timestamp"] as? NSTimeInterval {
            if connectivitySession.sensorDataFileTimestamps.contains(timestamp) {
                NSLog("Received duplicate timestamp file. Ignoring")
                return
            }
            connectivitySession.sensorDataFileTimestamps.insert(timestamp)
        }
        
        // decode the file
        let documentsUrl = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.CachesDirectory, NSSearchPathDomainMask.UserDomainMask, true).first!
        let timestamp = String(NSDate().timeIntervalSince1970)
        let fileUrl = NSURL(fileURLWithPath: documentsUrl).URLByAppendingPathComponent("sensordata-\(timestamp).raw")
        
        do {
            try NSFileManager.defaultManager().moveItemAtURL(file.fileURL, toURL: fileUrl)
            let data = NSData(contentsOfURL: fileUrl)!
            let new = try MKSensorData(decoding: data)
            if connectivitySession.sensorData != nil {
                try connectivitySession.sensorData!.append(new)
            } else {
                connectivitySession.sensorData = new
            }
            sensorDataConnectivityDelegate.sensorDataConnectivityDidReceiveSensorData(accumulated: connectivitySession.sensorData!, new: new, session: connectivitySession)
            sessions[index] = connectivitySession
            NSLog("\(file.metadata!) with \(new.duration); now accumulated \(connectivitySession.sensorData!.duration)")
        } catch {
            NSLog("\(error)")
        }
        
        // check to see if the file we've received is the only / last file we'll get
        if connectivitySession.last {
            sessions.removeAtIndex(index)
        }
    }
    
    /// Sends the models metadata to the watch
    public func sendModelsMetadata(models: [MKExerciseModelMetadata]) {
        var metadata = Dictionary<String, AnyObject>()
        models.forEach { id, name in
            metadata[id] = name
        }
        WCSession.defaultSession().transferUserInfo(metadata)
    }
    
}
