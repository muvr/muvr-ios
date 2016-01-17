import Foundation
import MuvrKit

extension MRApp {
    
    func exerciseDetailsForExerciseIds(exerciseIds: [MKExercise.Id], favouring: MKExerciseType) -> [MKExerciseDetail] {
        let plannedDetails: [MKExerciseDetail] = exerciseIds.map { exerciseId in
            let properties = exercisePropertiesForExerciseId(exerciseId)
            let type = MKExerciseType(exerciseId: exerciseId)!
            return (exerciseId, type, properties)
        }
        var otherDetails: [MKExerciseDetail] = exerciseDetails.filter { exerciseDetail in
            return !exerciseIds.contains { $0 == exerciseDetail.0 }
        }
        
        otherDetails.sortInPlace { l, r in
            switch (l.1 == favouring, r.1 == favouring) {
            case (true, true): return MKExercise.title(l.0) < MKExercise.title(r.0)
            case (true, false): return true
            case (false, true): return false
            case (false, false): return MKExercise.title(l.0) < MKExercise.title(r.0)
            }
        }
        
        return plannedDetails + otherDetails
    }
    
}
