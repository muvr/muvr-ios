import Foundation
import WatchConnectivity

///
/// The iOS -> Watch connectivity
///
public class MKConnectivity : NSObject {
    private let session: MKConnectivitySession
    
    ///
    /// Initializes this instance, assigninf the metadata ans sensorData delegates.
    /// This call should only happen once
    ///
    /// -parameter metadata: the metadata delegate
    /// -parameter sensorData: the sensor data delegate
    ///
    public init(metadata: MKMetadataConnectivityDelegate) {
        self.session = MKConnectivitySession(metadata: metadata)
        super.init()
        
        metadata.metadataConnectivityDidReceiveExerciseModelMetadata(defaultExerciseModelMetadata)
        metadata.metadataConnectivityDidReceiveIntensities(defaultIntensities)
    }
    
    ///
    /// Sets the ``MKSensorDataConnectivityDelegate`` for the currently running session
    ///
    /// -parameter delegate: the new delegate or ``nil`` to clear
    ///
    func setSensorDataConnectivityDelegate(delegate: MKSensorDataConnectivityDelegate?) {
        session.sensorData = delegate
    }
    
}

class MKConnectivitySession : NSObject, WCSessionDelegate {
    private let metadata: MKMetadataConnectivityDelegate
    internal weak var sensorData: MKSensorDataConnectivityDelegate?

    init(metadata: MKMetadataConnectivityDelegate) {
        self.metadata = metadata
        super.init()
        
        WCSession.defaultSession().delegate = self
    }
    
}