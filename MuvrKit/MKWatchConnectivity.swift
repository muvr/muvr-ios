import Foundation
import WatchConnectivity

///
/// The iOS -> Watch connectivity
///
public class MKConnectivity : NSObject, WCSessionDelegate {
    
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
    /// Starts the exercise session with the given 
    ///
    public func startSession(exerciseModelId exerciseModelId: MKExerciseModelId) {
        let message: [String : AnyObject] = [ "action" : "start", "exerciseModelId" : exerciseModelId ]
        WCSession.defaultSession().sendMessage(message, replyHandler: { _ -> Void in
            print("Reply")
            }) { (err) -> Void in
            print(err)
        }
    }

}