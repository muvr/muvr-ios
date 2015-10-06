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
    public init(delegate: MKMetadataConnectivityDelegate) {
        self.session = MKConnectivitySession(delegate: delegate)
        super.init()
        
        delegate.metadataConnectivityDidReceiveExerciseModelMetadata(defaultExerciseModelMetadata)
        delegate.metadataConnectivityDidReceiveIntensities(defaultIntensities)
    }
    
}

class MKConnectivitySession : NSObject, WCSessionDelegate {
    private let delegate: MKMetadataConnectivityDelegate

    init(delegate: MKMetadataConnectivityDelegate) {
        self.delegate = delegate
        super.init()
        
        WCSession.defaultSession().delegate = self
    }
    
}