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
    
    var labelsDescriptors: [MKExerciseLabelDescriptor] {
        switch self {
        case .Types: return [.Intensity]
        case .MuscleGroups(let exerciseType): return exerciseType.concrete.labelDescriptors
        case .Exercises: return MKExerciseTypeDescriptor.ResistanceTargeted.concrete.labelDescriptors
        }
    }
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
    
    // the average values
    let averages: [MKExerciseLabelDescriptor : Double]
    
    /// The average duration
    let averageDuration: NSTimeInterval
    
    ///
    /// A zero value suited for ``Array.reduce``.
    /// - parameter exerciseId: the exercise id
    /// - returns: the 0 element
    ///
    static func zero(labels: [MKExerciseLabelDescriptor]) -> MRAverage {
        let zeros: [MKExerciseLabelDescriptor:Double] = labels.reduce([:]) { (var d, l) in
            d[l] = 0
            return d
        }
        return MRAverage(count: 0, averages: zeros, averageDuration: 0)
    }
    
    func with(value: Double, forLabel label: MKExerciseLabelDescriptor) -> MRAverage {
        var averages = self.averages
        averages[label] = value
        return MRAverage(count: count, averages: averages, averageDuration: averageDuration)
    }
    
    ///
    /// Adds ``that`` to this value
    /// - parameter that: the other value
    /// - returns: self + that
    ///
    func plus(that: MRAverage) -> MRAverage {
        var averages: [MKExerciseLabelDescriptor : Double] = [:]
        self.averages.forEach { l1, v1 in
            for case let (l2, v2) in that.averages where l2 == l1 {
                averages[l1] = v1 + v2
            }
        }
        
        return MRAverage(
            count: count + that.count,
            averages: averages,
            averageDuration: averageDuration + that.averageDuration
        )
    }
    
    ///
    /// Divides ``self`` by ``const``
    /// - parameter const: the constant to divide the values by
    /// - returns: the updated value
    ///
    func divideBy(const: Double) -> MRAverage {
        var averages: [MKExerciseLabelDescriptor : Double] = [:]
        self.averages.forEach { l, v in
            averages[l] = v / const
        }
        return MRAverage(
            count: count,
            averages: averages,
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
