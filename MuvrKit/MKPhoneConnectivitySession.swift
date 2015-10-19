import Foundation

public struct MKExerciseConnectivitySession {
    internal(set) public var id: String
    /// accumulated sensor data
    internal(set) public var sensorData: MKSensorData?
    /// batch session files
    internal(set) public var sensorDataFiles: [NSURL] = []
    internal(set) public var sensorDataFileTimestamps = Set<NSTimeInterval>()
    internal(set) public var running: Bool = true
 
    internal init(id: String) {
        self.id = id
    }
}
