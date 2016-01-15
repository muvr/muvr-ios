import Foundation

public enum MKExerciseLabel {
    
    case Weight(weight: Double)
    
    case Repetitions(repetitions: Int)
    
    case Intensity(intensity: Double)
    
    // case AverageHeartRate(heartRate: Double)
    
    // case Distance(distance: Double)
    
    // ...
    
    var descriptor: MKExerciseLabelDescriptor {
        switch self {
        case .Weight: return .Weight
        case .Intensity: return .Intensity
        case .Repetitions: return .Repetitions
        }
    }
    
}
