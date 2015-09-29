import Foundation

///
/// MRExerciseModelId model.
///
/// In addition to driving the user interface elements, the ``id`` is a filter for the classifiers.
/// When a user starts an exercise session, the application needs to build a list of classifiers that
/// will be used to classify the incoming sensor data. It is likely that the same sensor patterns
/// idenfity different exercises, and the only reasonable way to distinguish between them is to use
/// the muscle group as additional context.
///
/// Moreover, not using all classifiers will improve the responsiveness of the app.
///
public struct MKExerciseModel {
    /// the identifier of the muscle group
    public let id: MKExerciseModelId
    /// the title
    public let title: String
    /// the exercises
    public let exerciseIds: [MKExerciseId]
    
    public init(id: MKExerciseId, title: String, exerciseIds: [MKExerciseId]) {
        self.id = id
        self.title = title
        self.exerciseIds = exerciseIds
    }
}
