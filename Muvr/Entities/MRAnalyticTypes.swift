import Foundation
import MuvrKit

/// What value to aggregate / summarize on
enum MRAggregate {
    /// All types, returning ``Key.ExerciseType``
    case types
    /// All muscle groups in a given type, returning ``Key.MuscleGroup`` or ``Key.NoMuscleGroup``
    case muscleGroups(inType: MKExerciseTypeDescriptor)
    /// All exercises in a given muscle group, returning ``Key.Exercise``
    case exercises(inMuscleGroup: MKMuscleGroup)
    
    var labelsDescriptors: [MKExerciseLabelDescriptor] {
        switch self {
        case .types: return [.intensity]
        case .muscleGroups(let exerciseType): return exerciseType.concrete.labelDescriptors
        case .exercises: return MKExerciseTypeDescriptor.resistanceTargeted.concrete.labelDescriptors
        }
    }
}

/// The aggregation key
enum MRAggregateKey : Hashable {
    case exerciseType(exerciseType: MKExerciseTypeDescriptor)
    case noMuscleGroup
    case muscleGroup(muscleGroup: MKMuscleGroup)
    case exercise(id: MKExercise.Id)
    
    var hashValue: Int {
        switch self {
        case .exerciseType(let exerciseType): return exerciseType.hashValue
        case .muscleGroup(let muscleGroup): return Int.multiplyWithOverflow(17, muscleGroup.hashValue).0
        case .exercise(let exerciseId): return Int.multiplyWithOverflow(31, exerciseId.hashValue).0
        case .noMuscleGroup: return 17
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
    let averageDuration: TimeInterval
    
    ///
    /// A zero value suited for ``Array.reduce``.
    /// - parameter exerciseId: the exercise id
    /// - returns: the 0 element
    ///
    static func zero(_ labels: [MKExerciseLabelDescriptor]) -> MRAverage {
        var zeros: [MKExerciseLabelDescriptor:Double] = [:]
        for label in labels {
            zeros[label] = 0
        }
        return MRAverage(count: 0, averages: zeros, averageDuration: 0)
    }
    
    func with(_ value: Double, forLabel label: MKExerciseLabelDescriptor) -> MRAverage {
        var averages = self.averages
        averages[label] = value
        return MRAverage(count: count, averages: averages, averageDuration: averageDuration)
    }
    
    ///
    /// Adds ``that`` to this value
    /// - parameter that: the other value
    /// - returns: self + that
    ///
    func plus(_ that: MRAverage) -> MRAverage {
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
    func divideBy(_ const: Double) -> MRAverage {
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
    case (.exercise(let l), .exercise(let r)): return l == r
    case (.muscleGroup(let l), .muscleGroup(let r)): return l == r
    case (.exerciseType(let l), .exerciseType(let r)): return l == r
    case (.noMuscleGroup, .noMuscleGroup): return true
    default: return false
    }
}
