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
