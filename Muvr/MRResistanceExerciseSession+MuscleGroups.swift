import Foundation

extension MRResistanceExerciseSession {
    
    ///
    /// Returns the hydrated MuscleGroups for the ids
    ///
    var muscleGroups: [MRMuscleGroup] {
        get {
            return muscleGroupIds.flatMap { id in
                return MRApplicationState.muscleGroups.find { $0.id == id }
            }
        }
    }
    
}