import Foundation
import MuvrKit

///
/// Adds localised title to the MKExerciseType.
///
extension MKExerciseType {
    
    /// The localised title for the type
    var title: String {
        switch self {
        case .resistanceTargeted(let muscleGroups): return (muscleGroups.map {"\($0)"}).joined(separator: ", ")
        case .resistanceWholeBody: return "Whole Body"
        case .indoorsCardio: return "Indoors Cardio"
        }
    }
    
}
