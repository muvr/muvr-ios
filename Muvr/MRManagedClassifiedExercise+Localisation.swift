import Foundation
import MuvrKit

///
/// Adds localised properties to ``Key``
///
extension MRManagedClassifiedExercise.Key {
    
    /// Localised title
    var title: String {
        switch self {
        case ExerciseType(let exerciseType): return exerciseType.title
        case NoMuscleGroup: return ""
        case MuscleGroup(let muscleGroup): return muscleGroup.title
        case Exercise(let exerciseId): return MRExerciseId.title(exerciseId)
        }
    }
    
}
