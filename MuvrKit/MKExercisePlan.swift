///
/// An exercise plan is a sequence of exercises
/// The exercise sequence is embedded into a Markov predictor
/// in order to provide predictions about the next exercise the user is
/// likely to perform.
/// This can be used to provide 'pre-defined' exercise plan to the user
/// or allow a user to 'export' his own exercise plans.
///
public struct MKExercisePlan {
    
    public typealias Id = String

    /// the exercise plan uuid
    public let id: Id
    /// the exercise plan name
    public let name: String
    /// the exercise plan type
    public let exerciseType: MKExerciseType
    /// the exercise sequence as a markov chain
    public let plan: MKMarkovPredictor<MKExercise.Id>
    /// the exercise sequence with their recommended values (duration, reps, rest, ...)
    public let items: [MKExercisePlanItem]
    
    
    /// Creates a fully initialized exercise plan
    public init(id: Id, name: String, exerciseType: MKExerciseType, plan: MKMarkovPredictor<MKExercise.Id>, items: [MKExercisePlanItem]) {
        self.id = id
        self.name = name
        self.exerciseType = exerciseType
        self.plan = plan
        self.items = items
    }
    
    /// Creates a fully initialized exercise plan by inserting the given exercises into the markov chain
    public init(id: Id, name: String, exerciseType: MKExerciseType, items: [MKExercisePlanItem]) {
        self.init(id: id, name: name, exerciseType: exerciseType, plan: MKMarkovPredictor<MKExercise.Id>(), items: items)
        
        // populate the markov chain by inserting 2x the exercises
        items.forEach { self.plan.insert($0.id) }
        items.forEach { self.plan.insert($0.id) }
    }
    
}