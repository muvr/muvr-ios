public typealias MKExerciseLabelsWithDuration = ([MKExerciseLabel], NSTimeInterval)

///
/// The interface implemented by label predictor.
/// Typically a prediction involves 2 phases:
/// - the prediction phase where the predictor is asked for the next labels of a given exercise
/// - the correction phase where the predictor is provided with the actual labels of a finished exercise
///
public protocol MKLabelsPredictor {
    
    ///
    /// dictionary containing the predictor's internal state
    /// this dictionary is used for json serialization
    ///
    var state: [String : AnyObject] { get }

    ///
    /// Predicts the next labels and duration for the upcoming exercise
    /// - parameter exerciseId: the upcoming exercise id
    /// - returns: the predicted labels and duration
    ///
    func predictLabelsForExerciseId(exerciseId: MKExercise.Id) -> MKExerciseLabelsWithDuration?
    
    ///
    /// Corrects the labels and duration for the finished exercise
    /// - parameter exerciseId: the finished exercise id
    /// - parameter labels: the actual labels and duration of the finished exercise
    ///
    func correctLabelsForExerciseId(exerciseId: MKExercise.Id, labels: MKExerciseLabelsWithDuration)
    
    ///
    /// Restores the predictor's internal state from the provided dictionary
    /// - parameter state: the unserialised state as a dictionary
    ///
    func restore(state: [String:AnyObject])
    
}

///
/// Extension to provide JSON serialisation of ``MKLabelsPredictor``
///
public extension MKLabelsPredictor {

    ///
    /// Serialize the predictor's internal ``state`` into a JSON NSData instance
    ///
    var json: NSData {
        return (try? NSJSONSerialization.dataWithJSONObject(state, options: [])) ?? NSData()
    }
    
    ///
    /// Unserialize the provided JSON NSData instance into a dictionary that is used to ``restore`` the predictor's internal state
    /// - parameter json: the JSON NSData
    ///
    func restore(json: NSData) throws {
        let dict = try! NSJSONSerialization.JSONObjectWithData(json, options: NSJSONReadingOptions.AllowFragments)
        let state = dict as! [String : AnyObject]
        self.restore(state)
    }
    
}