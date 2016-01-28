import Foundation

public enum MKAutoRegressionMethod: String {
    case LeastSquares
    case MaxEntropy
}

///
/// Implements the scalar predictor using nth degree polynomial approximation
///
public class MKAutoRegressionScalarPredictor : MKScalarPredictor {
    public typealias Round = (Double, MKExercise.Id) -> Double
    
    private(set) internal var coefficients: [Key:[Float]] = [:]
    /// The initial boost—no boost, really
    private var boost: Float = 1.0
    /// The last values needed to compute the next one
    /// Each [Float] is of length ``order``
    private(set) internal var simpleScalars: [Key:[Float]] = [:]
    /// The rounder to be used
    private let round: Round
    /// The order of the autoregression (number of past terms used)
    private let order: Int
    private let method: MKAutoRegressionMethod
    
    public typealias Key = MKExercise.Id
    
    ///
    /// Merges the coefficients in this instance with ``otherCoefficients``. This is typically
    /// used to update the coefficients when the user arrives at a different location: users
    /// actually vary their weight selection depending on location.
    ///
    /// - parameter otherCoefficients: the new (typically loaded for a new location) coefficients
    /// - parameter otherSimpleScalars: the new simple scalars
    ///
    public func mergeCoefficients(otherCoefficients: [Key:[Float]], otherSimpleScalars: [Key:[Float]]?) {
        for (nk, nv) in otherCoefficients {
            coefficients[nk] = nv
        }
        if let otherSimpleScalars = otherSimpleScalars {
            for (nk, nv) in otherSimpleScalars {
                simpleScalars[nk] = nv
            }
        }
    }
    
    ///
    /// Initializes empty instance with a given ``scalarRounder``.
    /// - parameter scalarRounder: the rounder
    ///
    public init(round: Round, order: Int = 5, method: MKAutoRegressionMethod) {
        self.round = round
        self.order = order
        self.method = method
    }
    
    ///
    /// Computes the prediction at ``x`` given the ``coefficients`` for, applying the rounding
    /// and according to ``exerciseId``.
    /// - parameter x: the independent value
    /// - parameter coefficients: the coefficients
    /// - parameter exerciseId: the exercise id (for rounding)
    /// - returns: the predicted value, boosted and rounded
    ///
    private func predictAndRound(forExerciseId exerciseId: Key) -> Float? {
        guard let xs = simpleScalars[exerciseId],
            let coefficients = coefficients[exerciseId] where xs.count >= coefficients.count else { return nil }
        let l = xs.count - 1
        let raw: Float = coefficients.enumerate().reduce(0) { (result, e) in
            let (n, c) = e
            return result + c * xs[l-n]
        }
        return Float(round(Double(raw * boost), exerciseId))
    }
    
    // Implements MKScalarPredictor
    public func setBoost(boost: Float) {
        self.boost = boost
    }
    
    // Implements MKScalarPredictor
    //
    // If the training set is too small, this function keeps at least the last value
    public func trainPositional(trainingSet: [Double], forExerciseId exerciseId: Key) {
        switch method {
        case .LeastSquares:
            if let coefs = try? MKAutoRegression.leastSquares(trainingSet.map { Float($0) } , order: min(trainingSet.count - 2, order)) {
                coefficients[exerciseId] = coefs
            }
        case .MaxEntropy:
            if let coefs = try? MKAutoRegression.maxEntropy(trainingSet.map { Float($0) } , order: min(trainingSet.count - 1, order)) {
                coefficients[exerciseId] = coefs
            }
        }
        
        if simpleScalars[exerciseId] == nil { simpleScalars[exerciseId] = [] }
        if let last = trainingSet.last {
            simpleScalars[exerciseId]?.append(Float(last))
        }
        if let l = simpleScalars[exerciseId]?.count where l > order {
            simpleScalars[exerciseId]?.removeFirst()
        }
        // NSLog("Coefficients \(coefficients[exerciseId]) - Sequence \(trainingSet)")
    }
    
    public func predictScalarForExerciseId(exerciseId: MKExercise.Id, n: Int) -> Double? {
        if let prediction = predictAndRound(forExerciseId: exerciseId) {
            return Double(prediction)
        }
        if let simpleScalar = simpleScalars[exerciseId]?.last {
            return Double(simpleScalar)
        }
        
        return nil
    }
    
}