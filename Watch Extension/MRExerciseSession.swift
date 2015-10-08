import Foundation
import CoreMotion
import HealthKit
import MuvrKit

class MRExerciseSession {
    private let motionManager: CMMotionManager
    private let startTime: NSDate
    private let exerciseModelMetadata: MKExerciseModelMetadata
    private unowned let connectivity: MKConnectivity
    
    init(connectivity: MKConnectivity, exerciseModelMetadata: MKExerciseModelMetadata) {
        self.connectivity = connectivity
        self.exerciseModelMetadata = exerciseModelMetadata
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
    var exerciseModelTitle: String {
        return exerciseModelMetadata.1
    }

}
