import Foundation
import MuvrKit

///
/// Adds conformance to the MKExercise protocol
/// 
/// This is slightly awkward because CoreData does not allow us to represent
/// primitive optionals directly, so we have to take a detour through naming the CD
/// properties differently (we use the ``cd`` prefix and ``NSNumber?`` type), and
/// then we implement the ``MKExercise`` protocol by delegating to those CD
/// properties.
///
extension MRManagedClassifiedExercise : MKExercise {
    
    var repetitions: Int32? {
        get {
            return cdRepetitions?.intValue
        }
    }
    
    var intensity: Double? {
        get {
            return cdIntensity?.doubleValue
        }
    }
    
    var weight: Double? {
        get {
            return cdWeight?.doubleValue
        }
    }
    
}
