///
/// An exercise plan is a sequence of exercises
///
public struct MKExercisePlan {

    /// the exercise plan uuid
    public let id: String
    /// the exercise plan name
    public let name: String
    /// the exercise plan type
    let exerciseType: MKExerciseType
    /// the exercise sequence as a markov chain
    let plan: MKMarkovPredictor<MKExercise.Id>
    
    /// Creates a fully initialized exercise plan
    public init(id: String, name: String, exerciseType: MKExerciseType, plan: MKMarkovPredictor<MKExercise.Id>) {
        self.id = id
        self.name = name
        self.exerciseType = exerciseType
        self.plan = plan
    }
    
    /// Creates an empty exercise plan
    public init(exerciseType: MKExerciseType) {
        self.id = NSUUID().UUIDString
        self.name = exerciseType.name
        self.exerciseType = exerciseType
        self.plan = MKMarkovPredictor<MKExercise.Id>()
    }
    
}

private extension MKExerciseType {

    /// name generated from the exercise type
    var name: String {
        switch self {
        case .IndoorsCardio: return "Cardio"
        case .ResistanceWholeBody: return "Whole body"
        case .ResistanceTargeted(let muscleGroups): return muscleGroups.map { $0.id }.joinWithSeparator(", ")
        }
    }
    
}