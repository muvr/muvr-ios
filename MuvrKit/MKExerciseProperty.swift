import Foundation

public enum MKExerciseProperty {
    
    case WeightProgression(minimum: Float, increment: Float, maximum: Float?)
    
    // A special sequence of weights
    // case WeightSequence(weights: [Float])
    
    // Think treadmill, cross-trainer
    // case Speed(minimum: Float, increment: Float, maximum: Float?)
    
    // Think rowing machine, simple spinning bike, ...
    // case Level(minimum: ...)
    
}