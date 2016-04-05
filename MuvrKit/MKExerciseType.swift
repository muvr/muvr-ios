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
    
    ///
    /// Indicates whether self is contained in that. This is useful for targeted 
    /// resistance with multiple muscle groups, where strict equality does not work
    /// - parameter that: the other ET
    /// - returns: true if self is contained within that
    ///
    public func isContainedWithin(that: MKExerciseType) -> Bool {
        switch (self, that) {
        case (.ResistanceTargeted(let lmgs), .ResistanceTargeted(let rmgs)):
            return lmgs.reduce(true) { result, lmg in
                return rmgs.contains(lmg)
            }
        case (.IndoorsCardio, .IndoorsCardio): return true
        case (.ResistanceWholeBody, .ResistanceWholeBody): return true
        default: return false
        }
    }
    
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
    /// Returns the label descriptors that an exercise type expects
    ///
    public var labelDescriptors: [MKExerciseLabelDescriptor] {
        switch self {
        case .IndoorsCardio: return [.Intensity]
        case .ResistanceTargeted: return [.Repetitions, .Weight, .Intensity]
        case .ResistanceWholeBody: return [.Repetitions, .Weight, .Intensity]
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
