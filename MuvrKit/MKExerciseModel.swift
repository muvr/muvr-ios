import Foundation

public struct MKExerciseModel {
    public typealias Id = String
    public typealias Label = (MKExercise.Id, MKExerciseTypeDescriptor)
    
    /// the network topology
    internal let layerConfiguration: [MKLayerConfiguration]
    /// the network weights
    internal let weights: [Float]
    /// the required sensor data types
    internal let sensorDataTypes: [MKSensorDataType]
    /// the minimum set duration
    internal let minimumDuration: TimeInterval
    /// the exercises as labels
    public let labels: [Label]
    
    public init(layerConfiguration: [MKLayerConfiguration], weights: [Float], sensorDataTypes: [MKSensorDataType], labels: [Label], minimumDuration: TimeInterval) {
        self.layerConfiguration = layerConfiguration
        self.sensorDataTypes = sensorDataTypes
        self.weights = weights
        self.labels = labels
        self.minimumDuration = minimumDuration
    }
    
    ///  dimensionality of the input layer
    var inputDimension: Int {
        return layerConfiguration[0].size
    }
    
    func exerciseTypeDescriptorForExerciseId(_ id: MKExercise.Id) -> MKExerciseTypeDescriptor? {
        for (labelId, labelTypeDescriptor) in labels {
            if labelId == id {
                return labelTypeDescriptor
            }
        }
        return nil
    }
    
}
