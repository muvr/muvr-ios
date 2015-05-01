import Foundation

struct MRResistanceExerciseSession {
    var startDate: NSDate
    var intendedIntensity: Double
    var muscleGroupIds: [MRMuscleGroupId]
    var sets: [MRResistanceExerciseSet]
}
