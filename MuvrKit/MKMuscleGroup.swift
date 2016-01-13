import Foundation

/// Muscle groups
public enum MKMuscleGroup {
    
    /// Arms: biceps, triceps, forearm, etc.
    case Arms
    
    /// Core muscles
    case Core
    
    /// Shoulders, including trapezoids
    case Shoulders
    
    /// All chest muscle groups
    case Chest
    
    /// All back muscle groups
    case Back
    
    /// Legs, including glutes
    case Legs
    
    ///
    /// Initializes this enum value from the String ``id``. Viz the ``id`` property.
    /// - parameter id: the muscle group identity.
    ///
    public init?(id: String) {
        switch id {
        case MKMuscleGroup.Arms.id: self = .Arms
        case MKMuscleGroup.Back.id: self = .Back
        case MKMuscleGroup.Chest.id: self = .Chest
        case MKMuscleGroup.Core.id: self = .Core
        case MKMuscleGroup.Legs.id: self = .Legs
        case MKMuscleGroup.Shoulders.id: self = .Shoulders
        default: return nil
        }
    }
 
    ///
    /// The string identity of the muscle group.
    ///
    public var id: String {
        switch self {
        case .Arms: return "arms"
        case .Back: return "back"
        case .Chest: return "chest"
        case .Core: return "core"
        case .Legs: return "legs"
        case .Shoulders: return "shoulders"
        }
    }

}
