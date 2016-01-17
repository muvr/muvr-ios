import Foundation
import MuvrKit

extension MRApp {
    
    ///
    /// Combines the given ``exerciseIds`` with all other exericses at the current location,
    /// favouring the given ``type``.
    /// - parameter exerciseIds: the exercise ids to start with
    /// - parameter type: the types to appear first
    /// - returns: the combined list of exercise details
    ///
    func exerciseDetailsForExerciseIds(exerciseIds: [MKExercise.Id], favouringType type: MKExerciseType) -> [MKExerciseDetail] {
        let plannedDetails: [MKExerciseDetail] = exerciseIds.map { exerciseId in
            let properties = exercisePropertiesForExerciseId(exerciseId)
            let type = MKExerciseType(exerciseId: exerciseId)!
            return (exerciseId, type, properties)
        }
        var otherDetails: [MKExerciseDetail] = exerciseDetails.filter { exerciseDetail in
            return !exerciseIds.contains { $0 == exerciseDetail.0 }
        }
        
        otherDetails.sortInPlace { l, r in
            switch (l.1 == type, r.1 == type) {
            case (true, true): return MKExercise.title(l.0) < MKExercise.title(r.0)
            case (true, false): return true
            case (false, true): return false
            case (false, false): return MKExercise.title(l.0) < MKExercise.title(r.0)
            }
        }
        
        return plannedDetails + otherDetails
    }
    
}
