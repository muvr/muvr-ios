import Foundation

extension MKExerciseType {
    
    var metadata: [String : AnyObject] {
        switch self {
        case .ResistanceTargeted(let muscleGroups): return ["id":id, "muscleGroups":muscleGroups.map { $0.id }]
        case .ResistanceWholeBody: return ["id":id]
        }
    }
    
    init?(metadata: [String : AnyObject]) {
        if let id = metadata["id"] as? String {
            if id == MKExerciseType.resistanceWholeBody {
                self = .ResistanceWholeBody
            } else if let muscleGroupsIds = (metadata["muscleGroups"] as? [String]) where id == MKExerciseType.resistanceTargeted {
                let muscleGroups = muscleGroupsIds.flatMap { MKMuscleGroup(id: $0) }
                self = .ResistanceTargeted(muscleGroups: muscleGroups)
            } else {
                return nil
            }
        } else {
            return nil
        }
    }
    
}

