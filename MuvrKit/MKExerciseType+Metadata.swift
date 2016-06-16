import Foundation

extension MKExerciseType {
    
    var metadata: [String : AnyObject] {
        switch self {
        case .resistanceTargeted(let muscleGroups): return ["id":id, "muscleGroups":muscleGroups.map { $0.id }]
        default: return ["id":id]
        }
    }
    
    init?(metadata: [String : AnyObject]) {
        if let id = metadata["id"] as? String {
            if id == MKExerciseType.resistanceWholeBody.id {
                self = .resistanceWholeBody
            } else if id == MKExerciseType.indoorsCardio.id {
                self = .indoorsCardio
            } else if let muscleGroupsIds = (metadata["muscleGroups"] as? [String]) where id == MKExerciseType.resistanceTargetedName {
                let muscleGroups = muscleGroupsIds.flatMap { MKMuscleGroup(id: $0) }
                self = .resistanceTargeted(muscleGroups: muscleGroups)
            } else {
                return nil
            }
        } else {
            return nil
        }
    }
    
}

