import WatchKit
import WatchConnectivity
import MuvrKit
import HealthKit

class MRExtensionDelegate : NSObject, WKExtensionDelegate, MKMetadataConnectivityDelegate {
    private var connectivity: MKConnectivity?
    private var exerciseModelMetadata: [MKExerciseModelMetadata] = []

    ///
    /// Convenience method that returns properly typed reference to this instance
    ///
    /// - returns: ``MRExtensionDelegate`` instance
    ///
    static func sharedDelegate() -> MRExtensionDelegate {
        return WKExtension.sharedExtension().delegate! as! MRExtensionDelegate
    }

    ///
    /// Returns the currently running session
    ///
    /// - returns: the running session or ``nil``
    ///
    var currentSession: MKExerciseSession? {
        return connectivity?.currentSession
    }
    
    ///
    /// Starts the session
    ///
    func startSession(exerciseModelMetadataIndex exerciseModelMetadataIndex: Int) {
        connectivity!.startSession(exerciseModelMetadata: exerciseModelMetadata[exerciseModelMetadataIndex])
    }
    
    ///
    /// Ends the session
    ///
    func endSession() {
        connectivity!.endSession()
    }
    
    ///
    /// Returns currenrly known models
    ///
    /// - returns: the model metadata
    ///
    func getExerciseModelMetadata() -> [MKExerciseModelMetadata] {
        return exerciseModelMetadata
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
        // Restart any tasks that were paused (or not yet started) while the application was inactive. 
        // If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillResignActive() {
        // connectivity?.getCurrentSession()?.endSendRealTime(nil)
    }
    
    // MARK: MKMetadataConnectivityDelegate

    func metadataConnectivityDidReceiveExerciseModelMetadata(exerciseModelMetadata: [MKExerciseModelMetadata]) {
        self.exerciseModelMetadata = exerciseModelMetadata
    }

}
