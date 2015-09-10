import Foundation

///
/// Implements the ordering and concatenating logic for the classification,
/// taking into account the different sources of data
///
struct MRExerciseSessionUserClassification {
    var classified: [MRClassifiedResistanceExercise]
    var other: [MRResistanceExercise]
    var data: NSData
    
    /// the combined view of the classified sets
    var combined: [MRClassifiedResistanceExercise] {
        return classified + other.map { MRClassifiedResistanceExercise($0) }
    }
    
    init(session: MRResistanceExerciseSession, data: NSData, result: [AnyObject]) {
        let rd = result as! [MRClassifiedResistanceExercise]
        self.classified = rd.sort { x, y in return x.confidence > y.confidence }
        // TODO: Fixme
        self.other = []
        self.data = data
        /*
        for mg in session.muscleGroupIds {
            MRApplicationState.exercises.forEach { exercise in
                if exercise.isInMuscleGroupId(mg) { self.other.append(exercise) }
            }
        }
        
        otherSets = exercises.map { MRResistanceExerciseSet($0) }
        self.data = data
        */
    }
    
}