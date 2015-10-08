import Foundation
import WatchConnectivity

///
/// The iOS -> Watch connectivity
///
public class MKConnectivity : NSObject, WCSessionDelegate {
    
    private var sensorDataTransferOnDone: (SendDataResult -> Void)? = nil
    
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
    public enum SendDataResult {
        ///
        /// The data was received by the receiver
        ///
        case Success
        
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
    public func beginTransferSensorData(data: MKSensorData, onDone: SendDataResult -> Void) {
        if sensorDataTransferOnDone == nil {
            sensorDataTransferOnDone = onDone
            
            let encoded = data.encode()
            let fileUrl = NSURL(fileURLWithPath: "sensordata.raw")
            encoded.writeToURL(fileUrl, atomically: true)
            WCSession.defaultSession().transferFile(fileUrl, metadata: nil)
        }
    }
    
    public func session(session: WCSession, didFinishFileTransfer fileTransfer: WCSessionFileTransfer, error: NSError?) {
        if let onDone = sensorDataTransferOnDone {
            if let e = error {
                onDone(.Error(error: e))
            } else {
                onDone(.Success)
            }
            sensorDataTransferOnDone = nil
        }
    }

    ///
    /// Starts the exercise session with the given 
    ///
    public func startSession(exerciseModelId exerciseModelId: MKExerciseModelId) {
        let message: [String : AnyObject] = [ "action" : "start", "exerciseModelId" : exerciseModelId ]
        print(__FUNCTION__)
        WCSession.defaultSession().sendMessage(message, replyHandler: { _ -> Void in
            print("Reply")
            }) { (err) -> Void in
            print(err)
        }
    }

}