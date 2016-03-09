import Foundation

public struct MKExerciseDetail {

    public let id: MKExercise.Id
    public let type: MKExerciseType
    public let labels: [MKExerciseLabelDescriptor]
    public let properties: [MKExerciseProperty]
    
    public init(id: MKExercise.Id, type: MKExerciseType, labels: [MKExerciseLabelDescriptor], properties: [MKExerciseProperty]) {
        self.id = id
        self.type = type
        self.labels = labels
        self.properties = properties
    }
    
}
