import Foundation
import WatchConnectivity

///
/// The iOS -> Watch connectivity
///
public class MKConnectivity : NSObject, WCSessionDelegate {
    typealias OnFileTransferDone = SendDataResult -> Void
    
    private var onFileTransferDone: OnFileTransferDone?
    private var currentSession: MKExerciseSession?
    
    ///
    /// Initializes this instance, assigninf the metadata ans sensorData delegates.
    /// This call should only happen once
    ///
    /// -parameter metadata: the metadata delegate
    /// -parameter sensorData: the sensor data delegate
    ///
    public init(delegate: MKMetadataConnectivityDelegate) {
        super.init()
        WCSession.defaultSession().delegate = self
        WCSession.defaultSession().activateSession()
        
        delegate.metadataConnectivityDidReceiveExerciseModelMetadata(defaultExerciseModelMetadata)
    }
    
    ///
    /// The response to data transmission
    ///
    enum SendDataResult {
        ///
        /// The data was received by the receiver
        ///
        case Success
        
        case NoSession
        
        ///
        /// The sending operation failed
        ///
        /// - parameter error: the reason for the error
        ///
        case Error(error: NSError)
        
    }
    
    ///
    /// Sends the sensor data ``data`` invoking ``onDone`` when the operation completes. The callee should
    /// check the value of ``SendDataResult`` to see if it should retry the transimssion, or if it can safely
    /// trim the data it has collected so far.
    ///
    /// - parameter data: the sensor data to be sent
    /// - parameter onDone: the function to be executed on completion (success or error)
    ///
    func transferSensorData(data: MKSensorData, onDone: OnFileTransferDone) {
        guard let currentSession = currentSession else { return onDone(.NoSession) }
        
        if onFileTransferDone == nil {
            onFileTransferDone = onDone
            let encoded = data.encode()
            let documentsUrl = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true).first!
            let fileUrl = NSURL(fileURLWithPath: documentsUrl).URLByAppendingPathComponent("sensordata.raw")
            
            if encoded.writeToURL(fileUrl, atomically: true) {
                WCSession.defaultSession().transferFile(fileUrl, metadata: ["sessionId" : currentSession.id])
            }
        }
    }
    
    ///
    /// Called when the file transfer completes.
    ///
    public func session(session: WCSession, didFinishFileTransfer fileTransfer: WCSessionFileTransfer, error: NSError?) {
        if let onDone = onFileTransferDone {
            if let e = error {
                onDone(.Error(error: e))
            } else {
                onDone(.Success)
            }
            
            onFileTransferDone = nil
        }
    }
    
    ///
    /// Ends the current session
    ///
    public func endSession() {
        if let currentSession = currentSession {
            let message: [String : AnyObject] = [ "action" : "end", "sessionId" : currentSession.id ]
            WCSession.defaultSession().transferUserInfo(message)
        }
        currentSession = nil
    }
    
    ///
    /// Returns the current session
    ///
    public func getCurrentSession() -> MKExerciseSession? {
        return currentSession
    }
    
    ///
    /// Starts the exercise session with the given 
    ///
    public func startSession(exerciseModelMetadata exerciseModelMetadata: MKExerciseModelMetadata) {
        if currentSession != nil { endSession() }
        
        currentSession = MKExerciseSession(connectivity: self, exerciseModelMetadata: exerciseModelMetadata)
        let message: [String : AnyObject] = [ "action" : "start", "exerciseModelId" : exerciseModelMetadata.0, "sessionId" : currentSession!.id ]
        WCSession.defaultSession().transferUserInfo(message)
    }

}