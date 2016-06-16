import Foundation
import MuvrKit

///
/// Adds localised properties to ``Key``
///
extension MRAggregateKey {
    
    /// Localised title
    var title: String {
        switch self {
        case exerciseType(let exerciseType): return exerciseType.title
        case noMuscleGroup: return "MRAggregateKey.noMuscleGroup".localized()
        case muscleGroup(let muscleGroup): return muscleGroup.title
        case exercise(let exerciseId): return MKExercise.title(exerciseId)
        }
    }
    
}
