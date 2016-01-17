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

}
