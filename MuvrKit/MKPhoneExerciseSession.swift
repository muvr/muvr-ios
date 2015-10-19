import Foundation

public struct MKExerciseSession {
    // TODO: Map of user-supplied (time range -> label)
    
    /// The classified (so far or completely) exercises in this session
    internal(set) public var classifiedExercises: [MKClassifiedExercise] = []
    /// The accumulated sensor data for this session
    internal(set) public var sensorData: MKSensorData? = nil
}
