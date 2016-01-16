import Foundation

///
/// A "tag" that can be attached to an exercise
///
public enum MKExerciseLabel {
    
    ///
    /// Weight in kilograms
    /// - parameter weight: the weight
    ///
    case Weight(weight: Double)
    
    ///
    /// The number of repetitions
    /// - parameter repetitions: the # repetitions
    ///
    case Repetitions(repetitions: Int)
    
    ///
    /// The intensity
    /// - parameter intensity: the intensity 0..1
    ///
    case Intensity(intensity: Double)
    
    // case AverageHeartRate(heartRate: Double)
    
    // case Distance(distance: Double)
    
    // ...

    ///
    /// The descriptor for each specific value
    ///
    var descriptor: MKExerciseLabelDescriptor {
        switch self {
        case .Weight: return .Weight
        case .Intensity: return .Intensity
        case .Repetitions: return .Repetitions
        }
    }
    
}
