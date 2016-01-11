import Foundation

/// The exercise type
public enum MKExerciseType : Equatable, Hashable {
        
    // case Cardio

    /// Whole-body resistance exercise, it targets all muscle groups
    case ResistanceWholeBody
    
    /// Specific resistance exercise targeting the given ``muscleGroups``
    /// - parameter muscleGroups: the muscle groups
    case ResistanceTargeted(muscleGroups: [MKMuscleGroup])

    // Implements Hashable
    public var hashValue: Int {
        get {
            switch self {
            // case .Cardio: return 1
            case .ResistanceWholeBody: return 17
            // case .ResistanceTargeted(_): return 31
            case .ResistanceTargeted(let mgs): return 31 + mgs.reduce(0) { Int.addWithOverflow($0, $1.hashValue).0 }
            }
        }
    }
    
    ///
    /// A more general representation of this type; think of it as less specific type.
    /// For example, for type .RT([a, b, c]) more generic type is .RT([a, b])
    ///
    public var moreGeneral: MKExerciseType? {
        switch self {
        case .ResistanceWholeBody: return nil
        case .ResistanceTargeted(let muscleGroups) where muscleGroups.count > 1:
            return .ResistanceTargeted(muscleGroups: Array(muscleGroups[0..<muscleGroups.count - 1]))
        default: return nil
        }
    }
    
}

// Implementation of Equatable
public func ==(lhs: MKExerciseType, rhs: MKExerciseType) -> Bool {
    switch (lhs, rhs) {
    // case (.Cardio, .Cardio): return true
    case (.ResistanceWholeBody, .ResistanceWholeBody): return true
    // case (.ResistanceTargeted(_), .ResistanceTargeted(_)): return true
    case (.ResistanceTargeted(let mgl), .ResistanceTargeted(let mgr)): return mgl.reduce(true) { r, mg in return r && mgr.contains(mg) }
    default: return false
    }
}
