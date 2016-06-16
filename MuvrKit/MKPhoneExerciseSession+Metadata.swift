extension MKExerciseSession {
    
    ///
    /// Serialize an MKExerciseSession object into a dictionary
    ///
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
    
    ///
    /// Builds an MKExerciseSession from values in a dictionary
    ///
    init?(metadata: [String: AnyObject]) {
        guard let id = metadata["id"] as? String,
            let start = metadata["start"] as? TimeInterval,
            let completed = metadata["completed"] as? Bool,
            let exerciseTypeMetadata = metadata["exerciseType"] as? [String: AnyObject],
            let exerciseType = MKExerciseType(metadata: exerciseTypeMetadata)
            else { return nil }
        
        let end = metadata["end"] as? TimeInterval
        self.init(
            id: id,
            start: Date(timeIntervalSinceReferenceDate: start),
            end: end.map { Date(timeIntervalSinceReferenceDate: $0) },
            completed: completed,
            exerciseType: exerciseType
        )
    }
    
}
