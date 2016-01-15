import Foundation
import MuvrKit

///
/// Adds localised properties to ``Key``
///
extension MRAggregateKey {
    
    /// Localised title
    var title: String {
        switch self {
        case ExerciseType(let exerciseType): return exerciseType.title
        case NoMuscleGroup: return NSLocalizedString("MRAggregateKey.noMuscleGroup", comment: "").localizedCapitalizedString
        case MuscleGroup(let muscleGroup): return muscleGroup.title
        case Exercise(let exerciseId): return MKExercise.title(exerciseId)
        }
    }
    
}
