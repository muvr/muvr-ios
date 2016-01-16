import Foundation
import MuvrKit

extension MKExerciseType {

    ///
    /// Parses the given ``exerciseId`` to ``MKExerciseType``.
    /// - parameter exerciseId: the exercise id.
    /// - returns: the parsed ``MKExerciseType`` or ``nil``.
    ///
    init?(exerciseId: String) {
        guard let (type, rest) = MKExercise.componentsFromExerciseId(exerciseId) else { return nil }
        if type == MKExerciseType.resistanceTargeted {
            guard let first = rest.first else { return nil }
            let mgs = first.componentsSeparatedByString(",").flatMap { MKMuscleGroup(id: $0) }
            self = MKExerciseType.ResistanceTargeted(muscleGroups: mgs)
        } else if type == MKExerciseType.indoorsCardio {
            self = .IndoorsCardio
        } else if type == MKExerciseType.resistanceWholeBody {
            self = .ResistanceWholeBody
        } else {
            return nil
        }
    }
    
    ///
    /// Returns the exercise id prefix
    ///
    var exerciseIdPrefix: String {
        var s = self.id + ":"
        if case .ResistanceTargeted(let muscleGroups) = self {
            s = s + muscleGroups.sort { $0.id < $1.id }.reduce("") { r, mg in return r + "," + mg.id }
        }
        return s
    }
        
}
