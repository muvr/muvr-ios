import Foundation
import MuvrKit

extension MKExerciseType {
    
    // TODO: Localise properly!
    var title: String {
        switch self {
        case .ResistanceTargeted(let muscleGroups):
            return (muscleGroups.map {"\($0)"}).joinWithSeparator(", ")
        case .ResistanceWholeBody:
            return "Whole Body"
        }
    }
    
}
