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
    func exerciseDetailsForExerciseIds(_ exerciseIds: [MKExercise.Id], favouringType type: MKExerciseType) -> [MKExerciseDetail] {
        let plannedDetails: [MKExerciseDetail] = exerciseIds.flatMap { exerciseDetailForExerciseId($0) }
        
        var otherDetails: [MKExerciseDetail] = exerciseDetails.filter { exerciseDetail in
            return !exerciseIds.contains { $0 == exerciseDetail.id }
        }
        
        otherDetails.sortInPlace { l, r in
            switch (l.type.isContainedWithin(type), r.type.isContainedWithin(type)) {
            case (true, false): return true
            case (false, true): return false
            default:
                if l.type == r.type {
                    return MKExercise.title(l.id) < MKExercise.title(r.id)
                } else {
                    return l.type < r.type
                }
            }
        }
        
        return plannedDetails + otherDetails
    }
    
}
