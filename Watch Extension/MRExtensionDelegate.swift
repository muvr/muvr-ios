import WatchKit
import WatchConnectivity
import MuvrKit

class MRExtensionDelegate : NSObject, WKExtensionDelegate, MKMetadataConnectivityDelegate {
    private var connectivity: MKConnectivity!
    private var modelMetadata: [MKExerciseModelMetadata] = []
    private var intensities: [MKIntensity] = []
    private var currentSession: MRExerciseSession?

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
    func getCurrentSession() -> MRExerciseSession? {
        return currentSession
    }
    
    ///
    /// Starts the session
    ///
    func startSession(modelMetadataIndex modelMetadataIndex: Int, intensityIndex: Int) {
        currentSession = nil
        currentSession = MRExerciseSession(connectivity: connectivity, modelMetadata: modelMetadata[modelMetadataIndex], intensity: intensities[intensityIndex])
    }
    
    ///
    /// Ends the session
    ///
    func endSession() {
        currentSession = nil
    }
    
    ///
    /// Returns currently known intensities
    ///
    /// - returns: the intensities
    ///
    func getIntensities() -> [MKIntensity] {
        return intensities
    }
    
    ///
    /// Returns currenrly known models
    ///
    /// - returns: the model metadata
    ///
    func getModelMetadata() -> [MKExerciseModelMetadata] {
        return modelMetadata
    }
    

    func applicationDidFinishLaunching() {
        connectivity = MKConnectivity(delegate: self)
    }

    func applicationDidBecomeActive() {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. 
        // If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillResignActive() {
    }
    
    // MARK: MKMetadataConnectivityDelegate

    func metadataConnectivityDidReceiveExerciseModelMetadata(modelMetadata: [MKExerciseModelMetadata]) {
        self.modelMetadata = modelMetadata
    }
    
    func metadataConnectivityDidReceiveIntensities(intensities: [MKIntensity]) {
        self.intensities = intensities
    }
}
