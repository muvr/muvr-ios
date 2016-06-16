import Foundation

///
/// A "tag" that can be attached to an exercise
///
public enum MKExerciseLabel : Equatable {
    
    ///
    /// Weight in kilograms
    /// - parameter weight: the weight
    ///
    case weight(weight: Double)
    
    ///
    /// The number of repetitions
    /// - parameter repetitions: the # repetitions
    ///
    case repetitions(repetitions: Int)
    
    ///
    /// The intensity
    /// - parameter intensity: the intensity 0..1
    ///
    case intensity(intensity: Double)
    
    // case AverageHeartRate(heartRate: Double)
    
    // case Distance(distance: Double)
    
    // ...

    ///
    /// The descriptor for each specific value
    ///
    public var descriptor: MKExerciseLabelDescriptor {
        switch self {
        case .weight: return .weight
        case .intensity: return .intensity
        case .repetitions: return .repetitions
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
    case (.weight(let l), .weight(let r)): return l == r
    case (.repetitions(let l), .repetitions(let r)): return l == r
    case (.intensity(let l), .intensity(let r)): return l == r
    default: return false
    }
}
