import Foundation

///
/// The planned exercise
///
//public struct MKPlannedExercise : Hashable, MKExercise {
//    /// The exercise id
//    public let exerciseId: MKExerciseId
//    /// Planned repetitions, if known
//    public let repetitions: Int32?
//    /// Planned intensity, if known
//    public let intensity: MKExerciseIntensity?
//    /// Planned weight, if known
//    public let weight: Double?
//    
//    public var confidence: Double { get { return 1.0 } }
//
//    ///
//    /// Initializes this instance, assigning all fields
//    ///
//    public init(exerciseId: MKExerciseId, repetitions: Int32 = 0, intensity: MKExerciseIntensity = 0, weight: Double = 0) {
//        self.exerciseId = exerciseId
//        self.repetitions = repetitions
//        self.intensity = intensity
//        self.weight = weight
//    }
//    
//    ///
//    /// Initializes this instance from the fields in ``classifiedExercise``
//    /// - parameter classifiedExercise: the CE
//    ///
//    public init(classifiedExercise: MKClassifiedExercise) {
//        self.exerciseId = classifiedExercise.exerciseId
//        self.repetitions = classifiedExercise.repetitions
//        self.intensity = classifiedExercise.intensity
//        self.weight = classifiedExercise.weight
//    }
//    
//    ///
//    /// Initializes this instance from the fields in ``labelledExercise``
//    /// - parameter labelledExercise: the LE
//    ///
//    public init(labelledExercise: MKLabelledExercise) {
//        self.exerciseId = labelledExercise.exerciseId
//        self.repetitions = Int32(labelledExercise.repetitions)
//        self.intensity = labelledExercise.intensity
//        self.weight = labelledExercise.weight
//    }
//    
//    ///
//    /// Returns the hash value
//    ///
//    public var hashValue: Int {
//        var h = exerciseId.hashValue
//        h = Int.addWithOverflow(h, 17 * (repetitions?.hashValue ?? 0)).0
//        h = Int.addWithOverflow(h, 17 * (intensity?.hashValue ?? 0)).0
//        h = Int.addWithOverflow(h, 17 * (weight?.hashValue ?? 0)).0
//        return h
//    }
//    
//}
//
/////
///// Equality for two planned exercises
/////
//public func ==(lhs: MKPlannedExercise, rhs: MKPlannedExercise) -> Bool {
//    if let l = lhs.repetitions, r = rhs.repetitions {
//        if l != r { return false }
//    }
//    if let l = lhs.intensity, r = rhs.intensity {
//        if abs(l - r) > 0.01 { return false }
//    }
//    if let l = lhs.weight, r = rhs.weight {
//        if abs(l - r) > 0.01 { return false }
//    }
//    
//    return lhs.exerciseId == rhs.exerciseId
//}
