import Foundation

/// A generalised mirror or MKExerciseType. It should match the values in
/// ``MKExerciseType``.
public enum MKExerciseTypeDescriptor {
    /// Whole body resistance exercise
    case resistanceWholeBody
    /// Targeted resistance exercise
    case resistanceTargeted
    /// Treadmill, cross trainer, etc
    case indoorsCardio
    
    /// Returns a concrete type from this general one
    public var concrete: MKExerciseType {
        switch self {
        case .resistanceWholeBody: return .resistanceWholeBody
        case .resistanceTargeted: return .resistanceTargeted(muscleGroups: [.arms, .core, .chest, .shoulders, .legs, .back])
        case .indoorsCardio: return .indoorsCardio
        }
    }
    
    ///
    /// The identity
    ///
    public var id: String {
        return concrete.id
    }
}
