import Foundation

///
/// A category of the MKExerciseLabel
///
public enum MKExerciseLabelDescriptor {
    
    /// Weight (for resistance exercises)
    case weight
    
    /// Number of repetitions (typically for resistance exercises)
    case repetitions
    
    /// Intensity (for all exercises)
    case intensity
    
    ///
    /// The identity of the descriptor
    ///
    public var id: String {
        switch self {
        case .weight: return "weight"
        case .repetitions: return "repetitions"
        case .intensity: return "intensity"
        }
    }
    
    ///
    /// Initializes a descriptor corresponding to the given id
    ///
    public init?(id: String) {
        switch id {
        case "weight": self = .weight
        case "repetitions": self = .repetitions
        case "intensity": self = .intensity
        default: return nil
        }
    }

}
