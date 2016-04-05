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
    internal let minimumDuration: NSTimeInterval
    /// the exercises as labels
    public let labels: [Label]
    
    public init(layerConfiguration: [MKLayerConfiguration], weights: [Float], sensorDataTypes: [MKSensorDataType], labels: [Label], minimumDuration: NSTimeInterval) {
        self.layerConfiguration = layerConfiguration
        self.sensorDataTypes = sensorDataTypes
        self.weights = weights
        self.labels = labels
        self.minimumDuration = minimumDuration
    }
    
    func exerciseTypeDescriptorForExerciseId(id: MKExercise.Id) -> MKExerciseTypeDescriptor? {
        for (labelId, labelTypeDescriptor) in labels {
            if labelId == id {
                return labelTypeDescriptor
            }
        }
        return nil
    }
    
}
