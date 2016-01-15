import Foundation

/// A generalised mirror or MKExerciseType. It should match the values in
/// ``MKExerciseType``.
public enum MKExerciseTypeDescriptor {
    /// Whole body resistance exercise
    case ResistanceWholeBody
    /// Targeted resistance exercise
    case ResistanceTargeted
    
    /// Returns a concrete type from this general one
    public var concrete: MKExerciseType {
        switch self {
        case .ResistanceWholeBody: return .ResistanceWholeBody
        case .ResistanceTargeted: return .ResistanceTargeted(muscleGroups: [.Arms, .Core, .Chest, .Shoulders, .Legs, .Back])
        }
    }
}
