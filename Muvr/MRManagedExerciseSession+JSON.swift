import Foundation

extension MRManagedClassifiedExercise {
    
    func toJson() -> NSDictionary {
        let d = NSMutableDictionary()
        d["start"] = start.utcString
        d["end"] = NSDate(timeInterval: duration, sinceDate: start).utcString
        d["exercise"] = exerciseId
        d["confidence"] = confidence
        if let intensity = intensity { d["intensity"] = intensity }
        if let repetitions = repetitions { d["repetitions"] = repetitions }
        if let weight = weight { d["weight"] = weight }
        return d
    }
    
}

extension MRManagedLabelledExercise {
    
    func toJson() -> NSDictionary {
        let d = NSMutableDictionary()
        d["start"] = start.utcString
        d["end"] = end.utcString
        d["exercise"] = exerciseId
        d["intensity"] = intensity
        d["repetitions"] = Int(repetitions)
        d["weight"] = weight
        return d
    }
    
}

extension MRManagedExerciseSession {

    func toJson() -> NSDictionary {
        let d = NSMutableDictionary()
        d["id"] = id
        d["start"] = start.utcString
        if let end = end { d["end"] = end.utcString }
        d["model"] = exerciseModelId
        d["completed"] = completed ? 1 : 0
        if let exercises = classifiedExercises.allObjects as? [MRManagedClassifiedExercise] {
            d["classifiedExercises"] = exercises.map { return $0.toJson() }
        }
        if let exercises = labelledExercises.allObjects as? [MRManagedLabelledExercise] {
            d["labelledExercises"] = exercises.map { return $0.toJson() }
        }
        return d
    }
    
}