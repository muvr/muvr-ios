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
 
    internal init(id: String, exerciseModelId: String, startDate: NSDate) {
        self.id = id
        self.exerciseModelId = exerciseModelId
        self.startDate = startDate
    }
}
