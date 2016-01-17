import Foundation
import MuvrKit

extension MRApp {
    
    func exerciseDetailsForExerciseIds(exerciseIds: [MKExercise.Id], favouring: MKExerciseType) -> [MKExerciseDetail] {
        var details: [MKExerciseDetail] = exerciseIds.map { exerciseId in
            let properties = exercisePropertiesForExerciseId(exerciseId)
            let type = MKExerciseType(exerciseId: exerciseId)!
            return (exerciseId, type, properties)
        }
        for exerciseDetail in exerciseDetails {
            if (!exerciseIds.contains { $0 == exerciseDetail.0 }) {
                details.append(exerciseDetail)
            }
        }
        
        details.sortInPlace { l, r in
            switch (l.1 == favouring, r.1 == favouring) {
            case (true, true): return MKExercise.title(l.0) < MKExercise.title(r.0)
            case (true, false): return true
            case (false, true): return false
            case (false, false): return MKExercise.title(l.0) < MKExercise.title(r.0)
            }
        }
        
        return details
    }
    
}
