///
/// Tuple of (labels, duration, rest duration)
///
public typealias MKExerciseLabelsWithDuration = ([MKExerciseLabel], TimeInterval?, TimeInterval?)

///
/// The interface implemented by label predictor.
/// Typically a prediction involves 2 phases:
/// - the prediction phase where the predictor is asked for the next labels of a given exercise
/// - the correction phase where the predictor is provided with the actual labels of a finished exercise
///
public protocol MKLabelsPredictor {
    
    ///
    /// Predicts the next labels and duration for the upcoming exercise
    /// - parameter exerciseDetail: the upcoming exercise detail
    /// - returns: the predicted labels and duration
    ///
    func predictLabelsForExercise(_ exerciseDetail: MKExerciseDetail) -> MKExerciseLabelsWithDuration?
    
    ///
    /// Corrects the labels and duration for the finished exercise
    /// - parameter exerciseDetail: the finished exercise detail
    /// - parameter labels: the actual labels and duration of the finished exercise
    ///
    func correctLabelsForExercise(_ exerciseDetail: MKExerciseDetail, labels: MKExerciseLabelsWithDuration)
    
    ///
    /// Load a predefined plan in order to predict values according to the given plan
    /// - parameter plan: the predefined plan to load
    ///
    func loadPredefinedPlan(_ plan: MKExercisePlan)
    
    ///
    ///  The JSON representation of the predictor
    ///
    var json: Data { get }
    
}
