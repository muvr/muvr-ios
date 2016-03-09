import Foundation

public struct MKExerciseDetail {

    public let id: MKExercise.Id
    public let type: MKExerciseType
    public let properties: [MKExerciseProperty]
    
    public init(id: MKExercise.Id, type: MKExerciseType, properties: [MKExerciseProperty]) {
        self.id = id
        self.type = type
        self.properties = properties
    }
    
}
