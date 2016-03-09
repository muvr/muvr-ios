import Foundation

public struct MKExerciseDetail {

    public let id: MKExercise.Id
    public let type: MKExerciseType
    public let labels: [MKExerciseLabelDescriptor]
    public let properties: [MKExerciseProperty]
    public let muscle: MKMuscle?
    
    public init(id: MKExercise.Id, type: MKExerciseType, muscle: MKMuscle?, labels: [MKExerciseLabelDescriptor], properties: [MKExerciseProperty]) {
        self.id = id
        self.type = type
        self.labels = labels
        self.properties = properties
        self.muscle = muscle
    }
    
    public func isAlternativeOf(exerciseDetail: MKExerciseDetail) -> Bool {
        switch type {
        case .IndoorsCardio, .ResistanceWholeBody: return type == exerciseDetail.type
        case .ResistanceTargeted: return muscle == exerciseDetail.muscle
        }
    }
    
}
