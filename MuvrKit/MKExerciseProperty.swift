import Foundation

///
/// An exercise property that describes a particular exercise (and even more 
///
public enum MKExerciseProperty {
    
    ///
    /// The exercise has a selection of weights from minimum..maximum by increment
    /// - parameter minimum: the minimum weight
    /// - parameter step: the step
    /// - parameter maximum: the maximum weight
    ///
    case weightProgression(minimum: Double, step: Double, maximum: Double?)
    
    ///
    /// A typical duration for an entire exercise
    ///
    case typicalDuration(duration: TimeInterval)
    
    ///
    /// A typical duration for one repetition
    ///
    case oneRepetitionDuration(duration: TimeInterval)
    
    // A special sequence of weights
    // case WeightSequence(weights: [Float])
    
    // Think treadmill, cross-trainer
    // case Speed(minimum: Float, increment: Float, maximum: Float?)
    
    // Think rowing machine, simple spinning bike, ...
    // case Level(minimum: ...)
    
}
