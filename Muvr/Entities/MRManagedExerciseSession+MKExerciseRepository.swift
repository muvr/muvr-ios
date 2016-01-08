import Foundation
import MuvrKit

extension MRManagedExerciseSession : MKExerciseRepository {
    
    var allExerciseIds: [MKExerciseId] {
        get {
            return MRAppDelegate.sharedDelegate().exerciseIds(inModel: exerciseModelId)
        }
    }
    
    func exerciseIdsInExerciseType(type: MKExerciseType) -> [MKExerciseId] {
        return allExerciseIds.filter { type.containsExerciseId($0) }
    }
    
    func exerciseTypeForExerciseId(id: MKExerciseId) -> MKExerciseType {
        return MKExerciseType.fromExerciseId(id)!
    }

/*
    var exerciseGroups: [String] {
        let groups = MRAppDelegate.sharedDelegate().exerciseIds(model: exerciseModelId).map {
            return $0.componentsSeparatedByString("/")[0]
        }
        return Array(Set(groups)).sort()
    }
    
    func exercisesInGroup(group: String) -> [MKIncompleteExercise] {
        return MRAppDelegate.sharedDelegate().exerciseIds(model: exerciseModelId)
            .filter { $0.componentsSeparatedByString("/")[0] == group }
            .map { exerciseId in
                return MRIncompleteExercise(exerciseId: exerciseId, repetitions: nil, intensity: nil, weight: nil, confidence: 0)
        }
    }
*/
}
