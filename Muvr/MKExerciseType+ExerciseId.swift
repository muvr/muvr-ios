import Foundation
import MuvrKit

extension MKExerciseType {

    ///
    /// Parses the given ``exerciseId`` to ``MKExerciseType``.
    /// - parameter exerciseId: the exercise id.
    /// - returns: the parsed ``MKExerciseType`` or ``nil``.
    ///
    init?(exerciseId: String) {
        if let (type, rest) = MRExerciseId.componentsFromExerciseId(exerciseId) {
            if type == MKExerciseType.resistanceTargeted {
                if let x = (MKMuscleGroup(id: rest.first!).map { MKExerciseType.ResistanceTargeted(muscleGroups: [$0]) }) {
                    self = x
                } else {
                    return nil
                }
            } else if type == MKExerciseType.indoorsCardio {
                self = .IndoorsCardio
            } else if type == MKExerciseType.resistanceWholeBody {
                self = .ResistanceWholeBody
            } else {
                return nil
            }
        } else {
            return nil
        }
    }
        
}
