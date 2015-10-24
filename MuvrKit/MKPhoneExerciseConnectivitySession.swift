import Foundation

public struct MKExerciseConnectivitySession {
    /// the session id
    internal(set) public var id: String
    /// the model id
    internal(set) public var exerciseModelId: MKExerciseModelId
    /// the start timestamp
    internal(set) public var startDate: NSDate
    /// accumulated sensor data
    internal(set) public var sensorData: MKSensorData?
    /// the file datastamps
    internal var sensorDataFileTimestamps = Set<NSTimeInterval>()
 
    ///
    /// Initialises this instance, assigning the fields
    ///
    /// - parameter id: the session identity
    /// - parameter exerciseModelId: the exercise model identity
    /// - parameter startDate: the start date
    ///
    internal init(id: String, exerciseModelId: String, startDate: NSDate) {
        self.id = id
        self.exerciseModelId = exerciseModelId
        self.startDate = startDate
    }
}
