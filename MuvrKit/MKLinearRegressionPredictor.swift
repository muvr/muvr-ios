import Foundation

public class MKLinearRegressionPredictor: MKScalarPredictor {
    public typealias Round = (Double, MKExercise.Id) -> Double
    
    /// The rounder to be used
    private let round: Round
    
    // the default predictor
    private(set) internal var predictor: MKScalarPredictor
    
    // the coefficients to compute the value
    private(set) internal var coefficients: [MKExercise.Id: [Float]] = [:]
    
    // the degree used in the regression
    private let degree: Int
    
    public init(predictor: MKScalarPredictor, round: Round, degree: Int) {
        self.predictor = predictor
        self.round = round
        self.degree = degree
    }
    
    /// Initialize this predictor with the given metadata
    public func mergeMetadata(metadata: [String : AnyObject]) throws {
        if let predictor = metadata["predictor"] as? [String:AnyObject],
           let coefficients = metadata["coefficients"] as? [MKExercise.Id: [Float]] {
            try self.predictor.mergeMetadata(predictor)
            self.coefficients = coefficients
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
        predictor.trainPositional(trainingSet, forExerciseId: exerciseId)
    }
    
    public func trainRegression(trainingSet: [Double], forExerciseId exerciseId: MKExercise.Id, dependentTrainingSet: [[Double]]) {
        let coefficients = self.coefficients[exerciseId] ?? []
        if needToTrain(y: trainingSet, x: dependentTrainingSet, coefficients: coefficients) {
            let m = dependentTrainingSet.count
            let n = dependentTrainingSet[0].count
            var x = [Float](count: m * n, repeatedValue: 0)
            for i in 0..<m*n {
                let col = i % m
                let row = i / m
                x[i] = Float(dependentTrainingSet[col][row])
            }
            self.coefficients[exerciseId] = MKLinearRegression.train(x, y: trainingSet.map { Float($0) }, m: m, degree: degree)
        }
    }
    
    ///
    /// Naive accuracy to check if we need to train again
    /// Returns true if the accuracy is < 0.9
    ///
    private func needToTrain(y y: [Double], x: [[Double]], coefficients: [Float]) -> Bool {
        if coefficients.isEmpty { return true }
        if coefficients.count != x.count * degree + 1 { return true }
        
        let missed = y.enumerate().reduce(0) { missed, e in
            let (i, expected) = e
            let input = x.map { return $0[i] }
            let estimated = MKLinearRegression.estimate(input.map { Float($0) }, θ: coefficients)
            if abs(Float(expected) - estimated) > 0.1 {
                return missed + 1
            }
            return missed
        }
        
        return 10 * missed > y.count // more than 10% wrong, let's re-train!
    }
    
    ///
    /// Returns the scalar prediction for the ``n`` the instance of the ``exerciseId``
    /// - parameter exerciseId: the exercise id
    /// - parameter n: the exercise number, starting at 0
    /// - returns: the predicted weight
    ///
    public func predictScalarForExerciseId(exerciseId: MKExercise.Id, n: Int) -> Double? {
        return predictor.predictScalarForExerciseId(exerciseId, n: n)
    }
    
    public func predictScalar(forExerciseId exerciseId: MKExercise.Id, n: Int, values: [Double]) -> Double? {
        guard let coefficients = coefficients[exerciseId] else { return predictor.predictScalarForExerciseId(exerciseId, n: n) }
        let estimation = Double(MKLinearRegression.estimate(values.map { Float($0) }, θ: coefficients))
        return self.round(estimation, exerciseId)
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