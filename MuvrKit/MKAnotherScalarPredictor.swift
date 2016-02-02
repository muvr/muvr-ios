import Foundation

/// This predictor tries to predict what is the value for the nth set given all the nth sets from previous session
/// If there is  no known sets from previous sessions it uses a regular in-session predictor
public class MKAnotherScalarPredictor: MKScalarPredictor {
    
    public typealias Round = (Double, MKExercise.Id) -> Double
    public typealias Step = (Double, Int, MKExercise.Id) -> Double
    public typealias Predictor = () -> MKScalarPredictor
    
    // One predictor for each set (1 predictor for the 1 set, 1 predictor for the 2nd set, ...)
    private(set) internal var predictors: [MKScalarPredictor] = []
    // Need to keep track of the training sets as ``trainPositional`` receive the in-session training set
    // and we need to train over the past sessions instead
    private(set) internal var trainingSets: [[MKExercise.Id: [Double]]] = []
    // the predictor used when there is no known sets yet
    private(set) internal var defaultPredictor: MKScalarPredictor
    // a way to construct new predictors
    private let makePredictor: Predictor
    
    public init(makePredictor: Predictor) {
        self.makePredictor = makePredictor
        self.defaultPredictor = makePredictor()
    }
    
    /// update this instance with the given metadata
    public func mergeMetadata(metadata: [String : AnyObject]) throws {
        if let predictors = metadata["predictors"] as? [[String: AnyObject]],
            let trainingSets = metadata["trainingSets"] as? [[MKExercise.Id: [Double]]] {
                self.trainingSets = trainingSets
                self.predictors = try predictors.map { dict in
                    let predictor = self.makePredictor()
                    try predictor.mergeMetadata(dict)
                    return predictor
                }
                if let dict = metadata["defaultPredictor"] as? [String: AnyObject] {
                    try self.defaultPredictor.mergeMetadata(dict)
                }
        } else {
            throw MKScalarPredictorError.InitialisationError
        }
    }
    
    ///
    /// Trains the predictor with the given ``trainingSet`` and ``exerciseId``
    /// - parameter trainingSet: the training set
    /// - parameter exerciseId: the exercise id
    ///
    public func trainPositional(trainingSet: [Double], forExerciseId exerciseId: MKExercise.Id) {
        // trainingset contains in-session dataset (value for set 1, 2, ..., n of the current session)
        guard let value = trainingSet.last else { return }
        let n = trainingSet.count - 1
        // get the predictor for the nth set
        if predictors.count <= n {
            predictors.append(self.makePredictor())
        }
        let predictor = predictors[n]
        // get the training set for the nth set
        if trainingSets.count <= n {
            trainingSets.append([:])
        }
        if trainingSets[n][exerciseId] == nil {
            trainingSets[n][exerciseId] = []
        }
        trainingSets[n][exerciseId]?.append(value)
        // train the predictor over all past nth sets
        predictor.trainPositional(trainingSets[n][exerciseId]!, forExerciseId: exerciseId)

        // train in-session predictor as usual (over in-session training set)
        defaultPredictor.trainPositional(trainingSet, forExerciseId: exerciseId)
    }
    
    ///
    /// Returns the scalar prediction for the ``n`` the instance of the ``exerciseId``
    /// - parameter exerciseId: the exercise id
    /// - parameter n: the exercise number, starting at 0
    /// - returns: the predicted weight
    ///
    public func predictScalarForExerciseId(exerciseId: MKExercise.Id, n: Int) -> Double? {
        var prediction: Double? = nil
        if n < trainingSets.count && trainingSets[n][exerciseId] != nil {
            // there is data for the nth set of the given exercise
            prediction = predictors[n].predictScalarForExerciseId(exerciseId, n: trainingSets[n][exerciseId]!.count)
        }
        // if there is no prediction use the in-session predictor
        return prediction ?? defaultPredictor.predictScalarForExerciseId(exerciseId, n: n)
    }
    
    ///
    /// Sets the correct prediction for exerciseId at n
    /// - parameter exerciseId: the exercise id
    /// - parameter n: the exercise number, starting at 0
    /// - parameter actual: the actual value
    ///
    public func correctScalarForExerciseId(exerciseId: MKExercise.Id, n: Int, actual: Double) {
        // noop
    }
    
    ///
    /// Sets the boosting function to "motivate the headcounts"
    /// - parameter boost: the multiplier, typically close to 1.0
    ///
    public func setBoost(boost: Float) {
        // no boost yet
    }
}