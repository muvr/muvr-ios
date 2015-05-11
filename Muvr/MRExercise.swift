import Foundation

///
/// A single exercise mapping between
///
struct MRExercise {
    var id: MRExerciseId
    var title: String
    //var description: String
    //var video: NSURL
    
    func isInMuscleGroupId(muscleGroupId: MRMuscleGroupId) -> Bool {
        return startsWith(id, muscleGroupId)
    }
}