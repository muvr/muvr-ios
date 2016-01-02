import Foundation

extension MRManagedClassifiedExercise {

    var json: NSDictionary {
        let d = NSMutableDictionary()
        d["start"] = start.utcString
        d["end"] = NSDate(timeInterval: duration, sinceDate: start).utcString
        d["exercise"] = exerciseId
        d["confidence"] = confidence
        if let intensity = intensity { d["intensity"] = intensity }
        if let repetitions = repetitions { d["repetitions"] = Int(repetitions) }
        if let weight = weight { d["weight"] = weight }
        return d
    }
}

extension MRManagedLabelledExercise {

    var json: NSDictionary {
        let d = NSMutableDictionary()
        d["start"] = start.utcString
        d["end"] = (start.dateByAddingTimeInterval(duration)).utcString
        d["exercise"] = exerciseId
        d["intensity"] = intensity
        d["repetitions"] = Int(cdRepetitions)
        d["weight"] = weight
        return d
    }
}

extension MRManagedExerciseSession {
    
    var json: NSDictionary {
        let d = NSMutableDictionary()
        d["id"] = id
        d["start"] = start.utcString
        if let end = end { d["end"] = end.utcString }
        d["model"] = exerciseModelId
        d["completed"] = completed ? 1 : 0
        if let exercises = classifiedExercises.allObjects as? [MRManagedClassifiedExercise] {
            d["classifiedExercises"] = exercises.map { return $0.json }
        }
        if let exercises = labelledExercises.allObjects as? [MRManagedLabelledExercise] {
            d["labelledExercises"] = exercises.map { return $0.json }
        }
        return d
    }
    
}
