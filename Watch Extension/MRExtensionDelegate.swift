import WatchKit
import WatchConnectivity
import MuvrKit
import HealthKit

class MRExtensionDelegate : NSObject, WKExtensionDelegate, MKMetadataConnectivityDelegate {
    private var connectivity: MKConnectivity!
    private(set) internal var exerciseModelMetadata: [MKExerciseModelMetadata] = []

    ///
    /// Convenience method that returns properly typed reference to this instance
    ///
    /// - returns: ``MRExtensionDelegate`` instance
    ///
    static func sharedDelegate() -> MRExtensionDelegate {
        return WKExtension.sharedExtension().delegate! as! MRExtensionDelegate
    }
    
    /// The current session
    var currentSession: (MKExerciseSession, MKExerciseSessionProperties)? {
        return connectivity.currentSession
    }
    
    ///
    /// Starts the session
    ///
    func startSession(exerciseModelMetadataIndex exerciseModelMetadataIndex: Int, demo: Bool) {
        let (modelId, _) = exerciseModelMetadata[exerciseModelMetadataIndex]
        connectivity.startSession(modelId, demo: demo)
    }
    
    ///
    /// Ends the session
    ///
    func endLastSession() {
        connectivity.endLastSession()
    }
    
    func sendSamples(data: MKSensorData) {
        connectivity.beginTransferSampleForLastSession(data)
    }
    
    func applicationDidFinishLaunching() {
        connectivity = MKConnectivity(delegate: self)
        let typesToShare: Set<HKSampleType> = [HKWorkoutType.workoutType()]
        HKHealthStore().requestAuthorizationToShareTypes(typesToShare, readTypes: nil) { (x, y) -> Void in
            print(x)
            print(y)
        }
    }
    
    func applicationDidBecomeActive() {
        connectivity.beginTransfer()
    }

    func applicationWillResignActive() {

    }
    
    // MARK: MKMetadataConnectivityDelegate

    func metadataConnectivityDidReceiveExerciseModelMetadata(exerciseModelMetadata: [MKExerciseModelMetadata]) {
        self.exerciseModelMetadata = exerciseModelMetadata
    }

}
