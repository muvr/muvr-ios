import Foundation

extension MRResistanceExercisePlan {
    
    var localisedTitle: String {
        if let x = title { return x }
        return MRApplicationState.joinMuscleGroups(muscleGroupIds)
    }
    
}
