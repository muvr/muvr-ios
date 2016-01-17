import Foundation

///
/// Implements the scalar predictor using nth degree polynomial approximation
///
public class MKPolynomialFittingScalarPredictor : MKScalarPredictor {
    public typealias Round = (Double, MKExercise.Id) -> Double
    
    private(set) internal var coefficients: [Key:[Float]] = [:]
    /// The initial boost—no boost, really
    private var boost: Float = 1.0
    /// When there are too few values in the training set, this keeps the last value to provide
    /// at least some kind of prediction.
    private(set) internal var simpleScalars: [Key:Float] = [:]
    /// The rounder to be used
    private let round: Round

    public typealias Key = MKExercise.Id
    
    ///
    /// Merges the coefficients in this instance with ``otherCoefficients``. This is typically
    /// used to update the coefficients when the user arrives at a different location: users
    /// actually vary their weight selection depending on location.
    ///
    /// - parameter otherCoefficients: the new (typically loaded for a new location) coefficients
    /// - parameter otherSimpleScalars: the new simple scalars
    ///
    public func mergeCoefficients(otherCoefficients: [Key:[Float]], otherSimpleScalars: [Key:Float]?) {
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
    public init(round: Round) {
        self.round = round
    }
    
    ///
    /// Computes naive cost as a sum of absolute differences between ``actual`` and ``predicted``.
    /// - parameter actual: the actual values
    /// - parameter predicted: the predicted values
    /// - returns: the cost
    ///
    private func naiveCost(actual: [Float], predicted: [Float]) -> Float {
        return predicted.enumerate().reduce(0) { result, e in
            let (i, p) = e
            return result + powf(2, abs(actual[i] - p))
        }
    }
    
    ///
    /// Computes the prediction at ``x`` given the ``coefficients`` for, applying the rounding
    /// and according to ``exerciseId``. 
    /// - parameter x: the independent value
    /// - parameter coefficients: the coefficients
    /// - parameter exerciseId: the exercise id (for rounding)
    /// - returns: the predicted value, boosted and rounded
    ///
    private func predictAndRound(x: Float, coefficients: [Float], forExerciseId exerciseId: Key) -> Float {
        let raw: Float = coefficients.enumerate().reduce(0) { (result, e) in
            let (n, c) = e
            return result + c * powf(x, Float(n))
        }
        return Float(round(Double(raw * boost), exerciseId))
    }
    
    // Implements MKScalarPredictor
    public func setBoost(boost: Float) {
        self.boost = boost
    }
    
    // Implements MKScalarPredictor
    //
    // This function can be executed very frequently; it first checks whether the current
    // coefficients are still applicable to the ``trainingSet``, only recomputing the
    // coefficients if not
    //
    // If the training set is too small, this function keeps at least the last value
    public func trainPositional(trainingSet: [Double], forExerciseId exerciseId: Key) {
        let x = trainingSet.enumerate().map { i, _ in return Float(i) }
        let y = trainingSet.map { Float($0) }

        var best: (Float, [Float])?

        if let coefficients = coefficients[exerciseId] {
            // first, re-evaluate what we already have.
            let cost = naiveCost(y, predicted: x.map { predictAndRound($0, coefficients: coefficients, forExerciseId: exerciseId) })
            if cost == 0 {
                // what we have is perfect. no need for any more work.
                return
            }
            best = (cost, coefficients)
        }

        let minimumTrainingSetSize = 2
        if trainingSet.count >= minimumTrainingSetSize {
            // next, see if the new training set provides a better match
            for degree in 1...min(trainingSet.count, 15) {
                if let coefficients = try? MKPolynomialFitter.fit(x: x, y: y, degree: degree) {
                    let cost = naiveCost(y, predicted: x.map { predictAndRound($0, coefficients: coefficients, forExerciseId: exerciseId) })
                    if let (bestCost, _) = best {
                        if bestCost > cost { best = (cost, coefficients) }
                        if cost == 0 { break }
                    } else {
                        best = (cost, coefficients)
                    }
                }
            }
            
            if let (_, bestCoefficients) = best {
                NSLog("Trained \(bestCoefficients) for scalars \(trainingSet) for exercise \(exerciseId)")
                coefficients[exerciseId] = bestCoefficients
                simpleScalars[exerciseId] = nil
            }
        } else if let last = trainingSet.last {
            simpleScalars[exerciseId] = Float(last)
        }
    }
    
    public func predictScalarForExerciseId(exerciseId: MKExercise.Id, n: Int) -> Double? {
        let prediction = coefficients[exerciseId].map {
            predictAndRound(Float(n), coefficients: $0, forExerciseId: exerciseId)
        }
        if let prediction = prediction {
            return Double(prediction)
        }
        if let simpleScalar = simpleScalars[exerciseId] {
            return Double(simpleScalar)
        }
        
        return nil
    }
    
}