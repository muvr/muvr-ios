import Foundation

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
