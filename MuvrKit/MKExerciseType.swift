import Foundation

/// The exercise type
public enum MKExerciseType : Equatable, Hashable {
    
    public static let resistanceTargetedName = "resistanceTargeted"
    public static let resistanceWholeBodyName = "resistanceWholeBody"
    public static let indoorsCardioName = "indoorsCardio"
    
    /// General indoors cardio: treadmill, cross-trainer, even spinning at the moment
    case indoorsCardio

    /// Whole-body resistance exercise, it targets all muscle groups
    case resistanceWholeBody
    
    /// Specific resistance exercise targeting the given ``muscleGroups``
    /// - parameter muscleGroups: the muscle groups
    case resistanceTargeted(muscleGroups: [MKMuscleGroup])
    
    ///
    /// Indicates whether self is contained in that. This is useful for targeted 
    /// resistance with multiple muscle groups, where strict equality does not work
    /// - parameter that: the other ET
    /// - returns: true if self is contained within that
    ///
    public func isContainedWithin(_ that: MKExerciseType) -> Bool {
        switch (self, that) {
        case (.resistanceTargeted(let lmgs), .resistanceTargeted(let rmgs)):
            return lmgs.reduce(true) { result, lmg in
                return rmgs.contains(lmg)
            }
        case (.indoorsCardio, .indoorsCardio): return true
        case (.resistanceWholeBody, .resistanceWholeBody): return true
        default: return false
        }
    }
    
    // Implements Hashable
    public var hashValue: Int {
        get {
            switch self {
            case .indoorsCardio: return 1
            case .resistanceWholeBody: return 17
            case .resistanceTargeted(let mgs): return 31 + mgs.reduce(0) { Int.addWithOverflow($0, $1.hashValue).0 }
            }
        }
    }
    
    ///
    /// Returns the label descriptors that an exercise type expects
    ///
    public var labelDescriptors: [MKExerciseLabelDescriptor] {
        switch self {
        case .indoorsCardio: return [.intensity]
        case .resistanceTargeted: return [.repetitions, .weight, .intensity]
        case .resistanceWholeBody: return [.repetitions, .weight, .intensity]
        }
    }
    
    ///
    /// Returns the identity of the type
    ///
    public var id: String {
        switch self {
        case .resistanceTargeted: return MKExerciseType.resistanceTargetedName
        case .resistanceWholeBody: return MKExerciseType.resistanceWholeBodyName
        case .indoorsCardio: return MKExerciseType.indoorsCardioName
        }
    }

}

// Implementation of Equatable
public func ==(lhs: MKExerciseType, rhs: MKExerciseType) -> Bool {
    switch (lhs, rhs) {
    case (.indoorsCardio, .indoorsCardio): return true
    case (.resistanceWholeBody, .resistanceWholeBody): return true
    case (.resistanceTargeted(let mgl), .resistanceTargeted(let mgr)): return mgl.reduce(true) { r, mg in return r && mgr.contains(mg) }
    default: return false
    }
}
