import Foundation
import MuvrKit

/// What value to aggregate / summarize on
enum MRAggregate {
    /// All types, returning ``Key.ExerciseType``
    case Types
    /// All muscle groups in a given type, returning ``Key.MuscleGroup`` or ``Key.NoMuscleGroup``
    case MuscleGroups(inType: MKExerciseTypeDescriptor)
    /// All exercises in a given muscle group, returning ``Key.Exercise``
    case Exercises(inMuscleGroup: MKMuscleGroup)
}

/// The aggregation key
enum MRAggregateKey : Hashable {
    case ExerciseType(exerciseType: MKExerciseTypeDescriptor)
    case NoMuscleGroup
    case MuscleGroup(muscleGroup: MKMuscleGroup)
    case Exercise(id: MKExercise.Id)
    
    var hashValue: Int {
        switch self {
        case .ExerciseType(let exerciseType): return exerciseType.hashValue
        case .MuscleGroup(let muscleGroup): return Int.multiplyWithOverflow(17, muscleGroup.hashValue).0
        case .Exercise(let exerciseId): return Int.multiplyWithOverflow(31, exerciseId.hashValue).0
        case .NoMuscleGroup: return 17
        }
    }
}

///
/// Average view of an exercise with the given ``exerciseId``. For simple
/// analytics, it appears to be sufficient to record average intensity,
/// repetitions, weight and duration.
///
struct MRAverage {
    /// The number of entries that make up the average
    let count: Int
    
    /// The intensity
    let averageIntensity: Double
    /// The repetitions
    let averageRepetitions: Int
    /// The weight
    let averageWeight: Double
    /// The duration
    let averageDuration: NSTimeInterval
    
    ///
    /// A zero value suited for ``Array.reduce``.
    /// - parameter exerciseId: the exercise id
    /// - returns: the 0 element
    ///
    static func zero() -> MRAverage {
        return MRAverage(count: 0, averageIntensity: 0, averageRepetitions: 0, averageWeight: 0, averageDuration: 0)
    }
    
    ///
    /// Adds ``that`` to this value
    /// - parameter that: the other value
    /// - returns: self + that
    ///
    func plus(that: MRAverage) -> MRAverage {
        return MRAverage(
            count: count + that.count,
            averageIntensity: averageIntensity + that.averageIntensity,
            averageRepetitions: averageRepetitions + that.averageRepetitions,
            averageWeight: averageWeight + that.averageWeight,
            averageDuration: averageDuration + that.averageDuration
        )
    }
    
    ///
    /// Divides ``self`` by ``const``
    /// - parameter const: the constant to divide the values by
    /// - returns: the updated value
    ///
    func divideBy(const: Double) -> MRAverage {
        return MRAverage(
            count: count,
            averageIntensity: averageIntensity / const,
            averageRepetitions: Int(Double(averageRepetitions) / const),
            averageWeight: averageWeight / const,
            averageDuration: averageDuration / const
        )
    }
}

func ==(lhs: MRAggregateKey, rhs: MRAggregateKey) -> Bool {
    switch (lhs, rhs) {
    case (.Exercise(let l), .Exercise(let r)): return l == r
    case (.MuscleGroup(let l), .MuscleGroup(let r)): return l == r
    case (.ExerciseType(let l), .ExerciseType(let r)): return l == r
    case (.NoMuscleGroup, .NoMuscleGroup): return true
    default: return false
    }
}
