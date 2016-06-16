import Foundation

public struct MKExerciseConnectivitySession {
    /// the session id
    internal(set) public var id: String
    /// the start timestamp
    internal(set) public var start: Date
    /// the end timestamp
    internal(set) public var end: Date?
    /// the timestamp of the first recieved sample
    internal(set) public var realStart: Date?
    /// the timestamp of the start of the current exercise
    internal(set) public var currentExerciseStart: Date?
    /// last chunk of data received
    internal(set) public var last: Bool
    /// accumulated sensor data
    internal(set) public var sensorData: MKSensorData?
    /// the file datastamps
    internal var sensorDataFileTimestamps = Set<TimeInterval>()
    // the exercise type
    internal(set) public var exerciseType: MKExerciseType
 
    ///
    /// Initialises this instance, assigning the fields
    ///
    /// - parameter id: the session identity
    /// - parameter exerciseModelId: the exercise model identity
    /// - parameter startDate: the start date
    ///
    internal init(id: String, start: Date, end: Date?, last: Bool, exerciseType: MKExerciseType) {
        self.id = id
        self.start = start
        self.end = end
        self.last = last
        self.exerciseType = exerciseType
    }
    
    ///
    /// "Parses" the ``metadata`` to construct the ``MKExerciseConnectivitySession``, returning
    /// the parsed instance or nil.
    ///
    /// - parameter metadata: the metadata to be parsed
    /// - returns: the parsed instance
    ///
    init?(metadata: [String : AnyObject]) {
        guard let sessionId = metadata["id"] as? String,
            let startTimestamp = metadata["start"] as? Double,
            let exerciseType = metadata["exerciseType"] as? [String : AnyObject]
        else { return nil }
        
        let end = (metadata["end"] as? Double).map { Date(timeIntervalSinceReferenceDate: $0) }
        let last = (metadata["last"] as? Bool) ?? false

        self.init(
                    id: sessionId,
                    start: Date(timeIntervalSinceReferenceDate: startTimestamp),
                    end: end,
                    last: last,
                    exerciseType: MKExerciseType(metadata: exerciseType)!)
    }
    
    mutating func exerciseStarted() {
        self.currentExerciseStart = Date()
    }
}
