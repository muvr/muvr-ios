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