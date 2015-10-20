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
    /// batch session files
    internal(set) public var sensorDataFiles: [NSURL] = []
    /// indicates whether the session is in progress
    internal(set) public var running: Bool = true
    /// the file datastamps
    internal var sensorDataFileTimestamps = Set<NSTimeInterval>()
 
    internal init(id: String, exerciseModelId: String, startDate: NSDate) {
        self.id = id
        self.exerciseModelId = exerciseModelId
        self.startDate = startDate
    }
}
