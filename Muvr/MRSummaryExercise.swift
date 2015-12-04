import Foundation

///
/// This struct contains the summary of one type exercise to display on the view when sessions finish.
///
class MRSummaryExercise {
    var start: NSDate
    var duration: Double
    var exerciseId: String
    var sets: Int
    var repetitions: Int
    
    init(start: NSDate, exerciseId: String, duration: Double, sets: Int, reps: Int) {
        self.start = start
        self.exerciseId = exerciseId
        self.duration = duration
        self.sets = sets
        self.repetitions = reps
    }
}