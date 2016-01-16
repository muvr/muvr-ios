import Foundation

///
/// An exercise property that describes a particular exercise (and even more 
///
public enum MKExerciseProperty {
    
    ///
    /// The exercise has a selection of weights from minimum..maximum by increment
    /// - parameter minimum: the minimum weight
    /// - parameter increment: the increment
    /// - parameter maximum: the maximum weight
    ///
    case WeightProgression(minimum: Float, increment: Float, maximum: Float?)
    
    // A special sequence of weights
    // case WeightSequence(weights: [Float])
    
    // Think treadmill, cross-trainer
    // case Speed(minimum: Float, increment: Float, maximum: Float?)
    
    // Think rowing machine, simple spinning bike, ...
    // case Level(minimum: ...)
    
}
