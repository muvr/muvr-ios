import Foundation

extension MRManagedExerciseSession {

    var isActive: Bool {
        return self.end == nil
    }
    
    var isDataAwaiting: Bool {
        return !self.completed && NSDate().timeIntervalSinceDate(self.start) < 24*60*60
    }
 
    // update the index in tableview of both exercises
    func updateIndexExercises() {
        var i = 0
        var j = 0
        while (i < self.classifiedExercises.count && j < self.labelledExercises.count) {
            let ce = self.classifiedExercises.allObjects[i] as! MRManagedClassifiedExercise
            let le = self.labelledExercises.allObjects[j] as! MRManagedLabelledExercise
            if (ce.start.compare(le.start) == NSComparisonResult.OrderedAscending) {
                // time of ce < time of le
                ce.indexView = i + j
                i += 1
            } else {
                le.indexView = i + j
                j += 1
            }
        }
        while (i < self.classifiedExercises.count) {
            let ce = self.classifiedExercises.allObjects[i] as! MRManagedClassifiedExercise
            ce.indexView = i+j
            i += 1
        }
        while (j < self.labelledExercises.count) {
            let le = self.labelledExercises.allObjects[j] as! MRManagedLabelledExercise
            le.indexView = i+j
            j += 1
        }
    }
    
    func printExerciseIndex() {
        NSLog("ClassifiedExercise index:")
        self.classifiedExercises.forEach {any in
            let exer = any as! MRManagedClassifiedExercise
            NSLog("\(exer.start.formatTime()) - \(exer.indexView)")
        }
        NSLog("LabelledExercise index:")
        self.labelledExercises.forEach {any in
            let exer = any as! MRManagedLabelledExercise
            NSLog("\(exer.start.formatTime()) - \(exer.indexView)")
        }
    }
    
    func aggregateClassifiedExercises() {
        var summaryExercises: [MRSummaryExercise] = []
        self.classifiedExercises.forEach { element in
            let exercise = element as! MRManagedClassifiedExercise
            let existedExercises = summaryExercises.filter { summary in
                return summary.exerciseId == exercise.exerciseId
            }
            if existedExercises.count == 0 {
                let reps = (exercise.repetitions ?? 0).integerValue
                let newExercises = MRSummaryExercise(start: exercise.start, exerciseId: exercise.exerciseId, duration: exercise.duration, sets: 1, reps: reps)
                summaryExercises.append(newExercises)
            } else {
                existedExercises[0].duration = existedExercises[0].duration + exercise.duration
                existedExercises[0].sets = existedExercises[0].sets + 1
                existedExercises[0].repetitions = existedExercises[0].repetitions + (exercise.repetitions ?? 0).integerValue
            }
        }
        self.summaryExercises = summaryExercises
    }
    
}