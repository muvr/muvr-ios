import Foundation

public struct MKExerciseConnectivitySession {
    /// the session id
    internal(set) public var id: String
    /// the start timestamp
    internal(set) public var start: NSDate
    /// the end timestamp
    internal(set) public var end: NSDate?
    /// last chunk of data received
    internal(set) public var last: Bool
    /// accumulated sensor data
    internal(set) public var sensorData: MKSensorData?
    /// the file datastamps
    internal var sensorDataFileTimestamps = Set<NSTimeInterval>()
    // the exercise type
    internal(set) public var exerciseType: MKExerciseType
 
    ///
    /// Initialises this instance, assigning the fields
    ///
    /// - parameter id: the session identity
    /// - parameter exerciseModelId: the exercise model identity
    /// - parameter startDate: the start date
    ///
    internal init(id: String, start: NSDate, end: NSDate?, last: Bool, exerciseType: MKExerciseType) {
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
    internal static func fromMetadata(metadata: [String : AnyObject]) -> MKExerciseConnectivitySession? {
        let end = (metadata["end"] as? Double).map { NSDate(timeIntervalSince1970: $0) }
        let last = (metadata["last"] as? Bool) ?? false
        if let sessionId = metadata["sessionId"] as? String,
           let startTimestamp = metadata["start"] as? Double,
           let exerciseType = metadata["exerciseType"] as? [String : AnyObject] {
                return MKExerciseConnectivitySession(
                    id: sessionId,
                    start: NSDate(timeIntervalSince1970: startTimestamp),
                    end: end,
                    last: last,
                    exerciseType: MKExerciseType(metadata: exerciseType)!)
        }
        return nil
    }
}
