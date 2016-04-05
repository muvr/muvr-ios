import Foundation

///
/// Holds information related to an exercise:
/// - e.g. weights progression, targeted muscle, ...
///
public struct MKExerciseDetail {

    /// the exercise id
    public let id: MKExercise.Id
    /// the exercise type (e.g. ResistanceTargeted(Arms))
    public let type: MKExerciseType
    /// the labels available for this exercise (e.g Repetitions, Intensity)
    public let labels: [MKExerciseLabelDescriptor]
    /// the properties associated to the exercise (e.g. weight progression)
    public let properties: [MKExerciseProperty]
    /// the main muscles targeted by this exercise (if relevant)
    public let muscle: MKMuscle?
    
    ///
    /// Create a new instance with all the given properties
    ///
    public init(id: MKExercise.Id, type: MKExerciseType, muscle: MKMuscle?, labels: [MKExerciseLabelDescriptor], properties: [MKExerciseProperty]) {
        self.id = id
        self.type = type
        self.labels = labels
        self.properties = properties
        self.muscle = muscle
    }
    
    ///
    /// Check if 2 exercise are "similar": they both target the same muscles (if relevant) or are of the same type (e.g. indoors cardio)
    /// - parameter exerciseDetail: the other exercise detail to compare
    /// - returns true if both exercises are "similar"
    ///
    public func isAlternativeOf(exerciseDetail: MKExerciseDetail) -> Bool {
        switch type {
        case .IndoorsCardio, .ResistanceWholeBody: return type == exerciseDetail.type
        case .ResistanceTargeted: return muscle == exerciseDetail.muscle
        }
    }
    
}
