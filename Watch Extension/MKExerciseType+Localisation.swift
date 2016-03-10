import Foundation
import MuvrKit

///
/// Adds localised title to the MKExerciseType.
///
extension MKExerciseType {
    
    /// The localised title for the type
    var title: String {
        switch self {
        case .ResistanceTargeted(let muscleGroups):
            return (muscleGroups.map {"\($0)"}).joinWithSeparator(", ")
        case .ResistanceWholeBody:
            return "Whole Body"
        case .IndoorsCardio:
            return "Indoors Cardio"
        case .GenericExercise:
            return "Some Exercise"
        case .GenericNonExercise:
            return "No Exercise"
        }
    }
    
}
