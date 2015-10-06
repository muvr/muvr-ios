import Foundation
import CoreMotion
import HealthKit
import MuvrKit

class MRExerciseSession {
    private let motionManager: CMMotionManager
    private let startTime: NSDate
    private let modelMetadata: MKExerciseModelMetadata
    private let intensity: MKIntensity
    private unowned let connectivity: MKConnectivity
    
    init(connectivity: MKConnectivity, modelMetadata: MKExerciseModelMetadata, intensity: MKIntensity) {
        self.connectivity = connectivity
        self.modelMetadata = modelMetadata
        self.intensity = intensity
        self.startTime = NSDate()
        motionManager = CMMotionManager()
        motionManager.startDeviceMotionUpdatesToQueue(NSOperationQueue.currentQueue()!, withHandler: deviceMotionHandler)
    }
    
    deinit {
        motionManager.stopDeviceMotionUpdates()
    }
    
    private func deviceMotionHandler(motion: CMDeviceMotion?, error: NSError?) {
        //
    }
    
    ///
    /// The session title
    ///
    var modelTitle: String {
        return modelMetadata.1
    }

    ///
    /// The intensity title
    ///
    var intensityTitle: String {
        return intensity.title
    }
    
}
