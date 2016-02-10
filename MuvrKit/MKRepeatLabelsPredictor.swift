
/// A predictor that simply repeats the last labels values of a given exercise
public class MKRepeatLabelsPredictor: MKLabelsPredictor {

    internal var exercises: [MKExercise.Id:MKExerciseLabelsWithDuration] = [:]
    
    public init() { }
    
    public func predictLabels(forExercise exerciseId: MKExercise.Id) -> MKExerciseLabelsWithDuration? {
        return exercises[exerciseId]
    }
    
    public func correctLabels(forExercise exerciseId: MKExercise.Id, labels: MKExerciseLabelsWithDuration) {
        exercises[exerciseId] = labels
    }
    
}