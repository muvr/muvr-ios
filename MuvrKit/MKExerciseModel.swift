import Foundation

public struct MKExerciseModel {
    /// the network topology
    internal let layerConfig: [Int]
    /// the network weights
    internal let weights: NSData
    /// the required sensor data types
    internal let sensorDataTypes: [MKSensorDataType]
    /// the minimum set duration
    internal let minimumDuration: MKDuration
    /// the exercises as labels
    public let exerciseIds: [MKExerciseId]
    
    public init(layerConfig: [Int], weights: NSData, sensorDataTypes: [MKSensorDataType], exerciseIds: [MKExerciseId], minimumDuration: MKDuration) {
        self.layerConfig = layerConfig
        self.sensorDataTypes = sensorDataTypes
        self.weights = weights
        self.exerciseIds = exerciseIds
        self.minimumDuration = minimumDuration
    }
    
}
