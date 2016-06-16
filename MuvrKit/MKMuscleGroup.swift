import Foundation

/// Muscle groups
public enum MKMuscleGroup {
    
    /// Arms: biceps, triceps, forearm, etc.
    case arms
    
    /// Core muscles
    case core
    
    /// Shoulders, including trapezoids
    case shoulders
    
    /// All chest muscle groups
    case chest
    
    /// All back muscle groups
    case back
    
    /// Legs, including glutes
    case legs
    
    ///
    /// Initializes this enum value from the String ``id``. Viz the ``id`` property.
    /// - parameter id: the muscle group identity.
    ///
    public init?(id: String) {
        switch id {
        case MKMuscleGroup.arms.id: self = .arms
        case MKMuscleGroup.back.id: self = .back
        case MKMuscleGroup.chest.id: self = .chest
        case MKMuscleGroup.core.id: self = .core
        case MKMuscleGroup.legs.id: self = .legs
        case MKMuscleGroup.shoulders.id: self = .shoulders
        default: return nil
        }
    }
 
    ///
    /// The string identity of the muscle group.
    ///
    public var id: String {
        switch self {
        case .arms: return "arms"
        case .back: return "back"
        case .chest: return "chest"
        case .core: return "core"
        case .legs: return "legs"
        case .shoulders: return "shoulders"
        }
    }

}
