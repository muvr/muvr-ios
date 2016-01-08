import Foundation
import MuvrKit

extension MKGeneralExerciseType {
    private static let resistanceTargeted = "resistanceTargeted"
    private static let resistanceWholeBody = "resistanceWholeBody"

    ///
    /// Parses the given ``exerciseId`` to ``MKGeneralExerciseType``.
    /// - parameter exerciseId: the exercise id.
    /// - returns: the parsed ``MKExerciseType`` or ``nil``.
    ///
    static func fromExerciseId(exerciseId: String) -> MKGeneralExerciseType? {
        if let (type, _) = MRExerciseId.componentsFromExerciseId(exerciseId) {
            switch type {
            case resistanceTargeted: return .ResistanceTargeted
            case resistanceWholeBody: return .ResistanceWholeBody
            default: return nil
            }
        }
        return nil
    }

    var id: String {
        switch self {
        case .ResistanceTargeted: return MKGeneralExerciseType.resistanceTargeted
        case .ResistanceWholeBody: return MKGeneralExerciseType.resistanceWholeBody
        }
    }
    
}
