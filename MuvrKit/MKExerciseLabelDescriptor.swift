import Foundation

///
/// A category of the MKExerciseLabel
///
public enum MKExerciseLabelDescriptor {
    
    /// Weight (for resistance exercises)
    case Weight
    
    /// Number of repetitions (typically for resistance exercises)
    case Repetitions
    
    /// Intensity (for all exercises)
    case Intensity
    
    ///
    /// The identity of the descriptor
    ///
    public var id: String {
        switch self {
        case .Weight: return "weight"
        case .Repetitions: return "repetitions"
        case .Intensity: return "intensity"
        }
    }
    
    ///
    /// Initializes a descriptor corresponding to the given id
    ///
    public init?(id: String) {
        switch id {
        case "weight": self = .Weight
        case "repetitions": self = .Repetitions
        case "intensity": self = .Intensity
        default: return nil
        }
    }

}
