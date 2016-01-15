import Foundation

public struct MKExerciseModel {
    public typealias Id = String
    
    /// the network topology
    internal let layerConfiguration: [MKLayerConfiguration]
    /// the network weights
    internal let weights: [Float]
    /// the required sensor data types
    internal let sensorDataTypes: [MKSensorDataType]
    /// the minimum set duration
    internal let minimumDuration: MKDuration
    /// the exercises as labels
    public let exerciseIds: [(MKExerciseId, MKExerciseTypeDescriptor)]
    
    public init(layerConfiguration: [MKLayerConfiguration], weights: [Float], sensorDataTypes: [MKSensorDataType], exerciseIds: [MKExerciseId], minimumDuration: MKDuration) {
        self.layerConfiguration = layerConfiguration
        self.sensorDataTypes = sensorDataTypes
        self.weights = weights
        self.exerciseIds = exerciseIds
        self.minimumDuration = minimumDuration
    }
    
}
