import Foundation
import MuvrKit

extension MKExerciseTypeDescriptor {
    
    ///
    /// Parses the given ``exerciseId`` to ``MKGeneralExerciseType``.
    /// - parameter exerciseId: the exercise id.
    /// - returns: the parsed ``MKExerciseType`` or ``nil``.
    ///
    init?(exerciseId: MKExercise.Id) {
        guard let (type, _, _) = MKExercise.componentsFromExerciseId(exerciseId) else { return nil }
        if type == MKExerciseType.resistanceTargeted {
            self = .ResistanceTargeted
        } else if type == MKExerciseType.resistanceWholeBody {
            self = .ResistanceWholeBody
        } else if type == MKExerciseType.indoorsCardio {
            self = .IndoorsCardio
        } else {
            return nil
        }
    }
    
}
