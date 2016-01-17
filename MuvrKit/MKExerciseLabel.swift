import Foundation

///
/// A "tag" that can be attached to an exercise
///
public enum MKExerciseLabel : Equatable {
    
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
    public var descriptor: MKExerciseLabelDescriptor {
        switch self {
        case .Weight: return .Weight
        case .Intensity: return .Intensity
        case .Repetitions: return .Repetitions
        }
    }

    ///
    /// The identity of this value
    ///
    public var id: String {
        return descriptor.id
    }

}

public func ==(lhs: MKExerciseLabel, rhs: MKExerciseLabel) -> Bool {
    switch (lhs, rhs) {
    case (.Weight(let l), .Weight(let r)): return l == r
    case (.Repetitions(let l), .Repetitions(let r)): return l == r
    case (.Intensity(let l), .Intensity(let r)): return l == r
    default: return false
    }
}
