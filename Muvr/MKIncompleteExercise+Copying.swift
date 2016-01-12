import Foundation
import MuvrKit

///
/// Adds Scala-style copy function
///
extension MKIncompleteExercise {
    
    ///
    /// Copies this instance, updating the given values
    /// - parameter repetitions: the new repetitions
    /// - parameter weight: the new weight
    /// - parameter intensity: the new intensity
    /// - returns: the updated MKIncompleteExercise
    ///
    func copy(repetitions repetitions: Int32?, weight: Double?, intensity: MKExerciseIntensity?) -> MKIncompleteExercise {
        return MRIncompleteExercise(exerciseId: exerciseId, repetitions: repetitions, intensity: intensity, weight: weight, confidence: confidence)
    }
    
}
