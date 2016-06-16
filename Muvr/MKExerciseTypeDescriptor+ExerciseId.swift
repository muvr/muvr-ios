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
        if type == MKExerciseType.resistanceTargetedName {
            self = .resistanceTargeted
        } else if type == MKExerciseType.resistanceWholeBodyName {
            self = .resistanceWholeBody
        } else if type == MKExerciseType.indoorsCardioName {
            self = .indoorsCardio
        } else {
            return nil
        }
    }
    
}
