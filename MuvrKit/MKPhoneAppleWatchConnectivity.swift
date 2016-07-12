import Foundation
import WatchConnectivity

///
/// The iOS counterpart of the connectivity interface
///
public final class MKAppleWatchConnectivity : NSObject, WCSessionDelegate, MKDeviceConnectivity {
    /// all sessions
    private(set) public var sessions: [MKExerciseConnectivitySession] = []
    /// The delegate that will receive the sensor data
    public let sensorDataConnectivityDelegate: MKSensorDataConnectivityDelegate
    /// The delegate that will receive session calls
    public let exerciseConnectivitySessionDelegate: MKExerciseConnectivitySessionDelegate
    
    public var reachable: Bool {
        return WCSession.default().isReachable
    }

    public init(sensorDataConnectivityDelegate: MKSensorDataConnectivityDelegate, exerciseConnectivitySessionDelegate: MKExerciseConnectivitySessionDelegate) {
        self.sensorDataConnectivityDelegate = sensorDataConnectivityDelegate
        self.exerciseConnectivitySessionDelegate = exerciseConnectivitySessionDelegate
            
        super.init()
        // setup watch communication
        WCSession.default().delegate = self
        WCSession.default().activate()
    }
        
    ///
    /// Get the correct session instance (and its index) based on the received metadata
    /// Issues corresponding session start/end events
    ///
    private func resolveSession(_ metadata: [String:AnyObject]) -> (MKExerciseConnectivitySession, Int)? {
        guard let session = MKExerciseConnectivitySession(metadata: metadata) else { return nil }
        let index = sessions.index { $0.id == session.id } ?? sessions.count
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

    public func sessionDidBecomeInactive(_ session: WCSession) {
        
    }
    
    public func sessionDidDeactivate(_ session: WCSession) {
        
    }
    
    public func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: NSError?) {
        
    }
    
    public func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : AnyObject]) {
        _ = resolveSession(userInfo)
    }
    
    public func session(_ session: WCSession, didReceive file: WCSessionFile) {
        // we must have metadata
        guard let metadata = file.metadata else {
            NSLog("Missing metadata in \(file)")
            return
        }
        
        // the metadata must be convertible to a session
        guard let (cs, index) = resolveSession(metadata) else { return }
        var connectivitySession = cs

        // check for duplicate transmissions
        if let timestamp = metadata["timestamp"] as? TimeInterval {
            if connectivitySession.sensorDataFileTimestamps.contains(timestamp) {
                NSLog("Received duplicate timestamp file. Ignoring")
                return
            }
            connectivitySession.sensorDataFileTimestamps.insert(timestamp)
        }
        
        // decode the file
        let documentsUrl = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.cachesDirectory, FileManager.SearchPathDomainMask.userDomainMask, true).first!
        let timestamp = String(Date().timeIntervalSinceReferenceDate)
        let fileUrl = try! URL(fileURLWithPath: documentsUrl).appendingPathComponent("sensordata-\(timestamp).raw")
        
        do {
            try FileManager.default.moveItem(at: file.fileURL, to: fileUrl)
            let data = try! Data(contentsOf: fileUrl)
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
            sessions.remove(at: index)
        }
    }
    
    public func startSession(_ session: MKExerciseSession) {
        if WCSession.default().isReachable {
            WCSession.default().transferUserInfo(session.metadata)
        }
    }
    
    public func exerciseStarted(_ exercise: MKExerciseDetail, start: Date) {
        //TODO: report the current exercise
    }
    
    public func endSession(_ session: MKExerciseSession) {
        if WCSession.default().isReachable {
            WCSession.default().transferUserInfo(session.metadata)
        }
    }
    
}
