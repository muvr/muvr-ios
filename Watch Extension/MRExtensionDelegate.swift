import WatchKit
import WatchConnectivity
import MuvrKit

class MRExtensionDelegate : NSObject, WKExtensionDelegate, MKMetadataConnectivityDelegate {
    private var connectivity: MKConnectivity?
    var modelMetadata: [MKExerciseModelMetadata] = []
    var intensities: [MKIntensity] = []
    
    static func sharedDelegate() -> MRExtensionDelegate {
        return WKExtension.sharedExtension().delegate! as! MRExtensionDelegate
    }

    func applicationDidFinishLaunching() {
        
    }

    func applicationDidBecomeActive() {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        connectivity = MKConnectivity(metadata: self)
    }

    func applicationWillResignActive() {
        connectivity = nil
    }
    
    // MARK: MKMetadataConnectivityDelegate

    func metadataConnectivityDidReceiveExerciseModelMetadata(modelMetadata: [MKExerciseModelMetadata]) {
        self.modelMetadata = modelMetadata
    }
    
    func metadataConnectivityDidReceiveIntensities(intensities: [MKIntensity]) {
        self.intensities = intensities
    }
}
