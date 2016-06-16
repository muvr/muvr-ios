import Foundation
import MuvrKit

extension MKExerciseType {

    ///
    /// Parses the given ``exerciseId`` to ``MKExerciseType``.
    /// - parameter exerciseId: the exercise id.
    /// - returns: the parsed ``MKExerciseType`` or ``nil``.
    ///
    init?(exerciseId: String) {
        guard let (type, rest, _) = MKExercise.componentsFromExerciseId(exerciseId) else { return nil }
        if type == MKExerciseType.resistanceTargetedName {
            guard let first = rest.first else { return nil }
            let mgs = first.components(separatedBy: ",").flatMap { MKMuscleGroup(id: $0) }
            self = MKExerciseType.resistanceTargeted(muscleGroups: mgs)
        } else if type == MKExerciseType.indoorsCardioName {
            self = .indoorsCardio
        } else if type == MKExerciseType.resistanceWholeBodyName {
            self = .resistanceWholeBody
        } else {
            return nil
        }
    }
    
    ///
    /// Returns the exercise id prefix
    ///
    var exerciseIdPrefix: String {
        var s = self.id + ":"
        if case .resistanceTargeted(let muscleGroups) = self {
            s = s + muscleGroups.sorted { $0.id < $1.id }.reduce("") { r, mg in return r + "," + mg.id }
        }
        return s
    }
        
}
