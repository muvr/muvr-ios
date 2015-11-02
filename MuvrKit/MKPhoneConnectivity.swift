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
        if let session = MKExerciseConnectivitySession.fromMetadata(userInfo) {
            sessions.append(session)
            exerciseConnectivitySessionDelegate.exerciseConnectivitySessionDidStart(session: session)
        }
    }
    
    public func session(session: WCSession, didReceiveFile file: WCSessionFile) {
        // we must have metadata
        guard let metadata = file.metadata else {
            NSLog("Missing metadata in \(file)")
            return
        }
        
        // get the session matching the received metadata
        // if the session is known return it otherwise return a new session instance
        func resolveSession(metadata: [String : AnyObject]) -> MKExerciseConnectivitySession? {
            guard let receivedSession = MKExerciseConnectivitySession.fromMetadata(metadata) else { return nil}
            return sessions.indexOf({$0.id == receivedSession.id}).map({sessions[$0]}) ?? receivedSession
        }

        // the metadata must be convertible to a session
        guard var connectivitySession = resolveSession(metadata) else { return }
        if (!sessions.contains { $0.id == connectivitySession.id }) {
            // this is the first time we're seeing the file for a session. issue a session start.
            sessions.append(connectivitySession)
            exerciseConnectivitySessionDelegate.exerciseConnectivitySessionDidStart(session: connectivitySession)
        }
        
        NSLog("\(connectivitySession)")

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
            sessions[sessions.count - 1] = connectivitySession
            NSLog("\(file.metadata!) with \(new.duration); now accumulated \(connectivitySession.sensorData!.duration)")
        } catch {
            NSLog("\(error)")
        }
        
        // check to see if the file we've received is the only / last file we'll get
        if connectivitySession.end != nil {
            if let index = (sessions.indexOf { $0.id == connectivitySession.id }) {
                sessions.removeAtIndex(index)
                exerciseConnectivitySessionDelegate.exerciseConnectivitySessionDidEnd(session: connectivitySession)
            }
        }
    }
    
}
