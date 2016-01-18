extension MKExerciseSession {
    
    var metadata: [String: AnyObject] {
        var metadata: [String: AnyObject] = [
            "id": id,
            "start": start.timeIntervalSinceReferenceDate,
            "completed": completed,
            "exerciseType": exerciseType.metadata
        ]
        if let end = end {
            metadata["end"] = end.timeIntervalSinceReferenceDate
        }
        return metadata
    }
    
    init?(metadata: [String: AnyObject]) {
        guard let id = metadata["id"] as? String,
            let start = metadata["start"] as? NSTimeInterval,
            let completed = metadata["completed"] as? Bool,
            let exerciseTypeMetadata = metadata["exerciseType"] as? [String: AnyObject],
            let exerciseType = MKExerciseType(metadata: exerciseTypeMetadata)
            else { return nil }
        
        let end = metadata["end"] as? NSTimeInterval
        self.init(
            id: id,
            start: NSDate(timeIntervalSinceReferenceDate: start),
            end: end.map { NSDate(timeIntervalSinceReferenceDate: $0) },
            completed: completed,
            exerciseType: exerciseType
        )
    }
    
}
