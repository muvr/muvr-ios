import Foundation

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
