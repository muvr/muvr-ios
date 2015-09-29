import Foundation

public struct MKExerciseModel {
    /// the network topology
    internal let layerConfig: [Int]
    /// the network weights
    internal let weights: NSData
    /// the required sensor data types
    internal let sensorDataTypes: [MKSensorDataType]
    /// the exercises as labels
    public let exerciseIds: [MKExerciseId]
    
}
