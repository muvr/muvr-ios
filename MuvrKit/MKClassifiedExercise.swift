import Foundation

///
/// The result of classifying an exercise
///
public enum MKClassifiedExercise {

    ///
    /// Resistance exercise: typically short-duration weight-lifting
    ///
    /// - parameter confidence: the confidence (0..1)
    /// - parameter exerciseId: the exercise identity
    /// - parameter duration: the duration (in seconds)
    /// - parameter repetitions: the number of repetitions
    /// - parameter intensity: the intensity
    /// - parameter weight: the weight
    ///
    case Resistance(confidence: Double, exerciseId: MKExerciseId, duration: NSTimeInterval,
        repetitions: UInt?, intensity: MKExerciseIntensity?, weight: Double?)
    
    // case Aerobic(exerciseId: MKExerciseId, duration: NSTimeInterval, intensity: Double?)
    // case Pyhisiotherapy(exerciseId: MKExerciseId, duration: NSTimeInterval, accuracy: Double?)

    ///
    /// Gets the exercise id
    ///
    var exerciseId: MKExerciseId {
        switch self {
        case .Resistance(confidence: _, let exerciseId, duration: _, repetitions: _, intensity: _, weight: _): return exerciseId
        }
    }

    ///
    /// Gets the classification confidence
    ///
    var confidence: Double {
        switch self {
        case .Resistance(let confidence, exerciseId: _, duration: _, repetitions: _, intensity: _, weight: _): return confidence
        }
    }
    
}
