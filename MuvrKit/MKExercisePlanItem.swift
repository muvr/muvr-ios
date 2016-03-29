///
/// Exercise contained in an exercise plan
/// It allows to specify rest duration, duration and labels for any exercise
///
public struct MKExercisePlanItem {

    /// The exercise id
    let id: MKExercise.Id
    /// The recommended duration for this exercise
    let duration: NSTimeInterval?
    /// The recommended rest duration after this exercise
    let rest: NSTimeInterval?
    /// The recommended label values to apply for this exercise
    let labels: [MKExerciseLabel]?
    
    public init(id: MKExercise.Id, duration: NSTimeInterval?, rest: NSTimeInterval?, labels: [MKExerciseLabel]?) {
        self.id = id
        self.duration = duration
        self.rest = rest
        self.labels = labels
    }
    
}