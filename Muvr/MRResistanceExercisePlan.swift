import Foundation

struct MRResistanceExercisePlan {
    var title: String?
    var intendedIntensity: Double
    var muscleGroupIds: [MRMuscleGroupId]
    var exercises: [MRResistanceExercise]
}
