import Foundation
import MuvrKit

///
/// Provides the exercise id parsing functions
///
extension MKMuscleGroup {
   
    ///
    /// Parses the ``exerciseId`` and returns the muscle groups contained within it
    /// - parameter exerciseId: the exercise id 
    /// - returns: the muscle groups in the exercise id, ``nil`` on missing
    ///
    static func fromExerciseId(exerciseId: String) -> [MKMuscleGroup]? {
        let (_, rest) = MRExerciseId.componentsFromExerciseId(exerciseId)!
        if rest.count > 1 { return rest.first!.componentsSeparatedByString(",").flatMap(MKMuscleGroup.fromId) }
        return nil
    }

    ///
    /// Parses the muscle group identity. ∀e ∈ ``MKMuscleGroup``. fromId(e.id) == e.
    /// - parameter id: the identity of the muscle group
    /// - returns: the parsed muscle group or ``nil``
    ///
    static func fromId(id: String) -> MKMuscleGroup? {
        switch id {
        case "arms": return .Arms
        case "back": return .Back
        case "chest": return .Chest
        case "core": return .Core
        case "legs": return .Legs
        case "shoulders": return .Shoulders
        default: return nil
        }
    }

    ///
    /// The string identity of the muscle group.
    ///
    var id: String {
        switch self {
        case .Arms: return "arms"
        case .Back: return "back"
        case .Chest: return "chest"
        case .Core: return "core"
        case .Legs: return "legs"
        case .Shoulders: return "shoulders"
        }
    }

}
