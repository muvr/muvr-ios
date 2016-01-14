import Foundation

/// The exercise type
public enum MKExerciseType : Equatable, Hashable {
    
    public static let resistanceTargeted = "resistanceTargeted"
    public static let resistanceWholeBody = "resistanceWholeBody"
    public static let indoorsCardio = "indoorsCardio"
    
    /// General indoors cardio: treadmill, cross-trainer, even spinning at the moment
    case IndoorsCardio

    /// Whole-body resistance exercise, it targets all muscle groups
    case ResistanceWholeBody
    
    /// Specific resistance exercise targeting the given ``muscleGroups``
    /// - parameter muscleGroups: the muscle groups
    case ResistanceTargeted(muscleGroups: [MKMuscleGroup])

    // Implements Hashable
    public var hashValue: Int {
        get {
            switch self {
            case .IndoorsCardio: return 1
            case .ResistanceWholeBody: return 17
            case .ResistanceTargeted(let mgs): return 31 + mgs.reduce(0) { Int.addWithOverflow($0, $1.hashValue).0 }
            }
        }
    }
    
    ///
    /// Returns the identity of the type
    ///
    public var id: String {
        switch self {
        case .ResistanceTargeted: return MKExerciseType.resistanceTargeted
        case .ResistanceWholeBody: return MKExerciseType.resistanceWholeBody
        case .IndoorsCardio: return MKExerciseType.indoorsCardio
        }
    }

    ///
    /// A more general representation of this type; think of it as less specific type.
    /// For example, for type .RT([a, b, c]) more generic type is .RT([a, b])
    ///
    public var moreGeneral: MKExerciseType? {
        switch self {
        case .ResistanceTargeted(let muscleGroups) where muscleGroups.count > 1:
            return .ResistanceTargeted(muscleGroups: Array(muscleGroups[0..<muscleGroups.count - 1]))
        default: return nil
        }
    }
}

// Implementation of Equatable
public func ==(lhs: MKExerciseType, rhs: MKExerciseType) -> Bool {
    switch (lhs, rhs) {
    case (.IndoorsCardio, .IndoorsCardio): return true
    case (.ResistanceWholeBody, .ResistanceWholeBody): return true
    case (.ResistanceTargeted(let mgl), .ResistanceTargeted(let mgr)): return mgl.reduce(true) { r, mg in return r && mgr.contains(mg) }
    default: return false
    }
}
