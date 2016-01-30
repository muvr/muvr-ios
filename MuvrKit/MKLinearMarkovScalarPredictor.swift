public class MKLinearMarkovScalarPredictor : MKScalarPredictor {
    
    /// Takes a [raw] value for an exercise id and returns a rounded value
    public typealias Round = (Double, MKExercise.Id) -> Double
    /// Takes a [raw] value, the number of steps for an exercise id and returns a value n steps down or up
    public typealias Step = (Double, Int, MKExercise.Id) -> Double
    
    typealias Correction = Int
    
    internal let linearPredictor: MKPolynomialFittingScalarPredictor
    private let round: Round
    private let step: Step
    private let maxCorrectionSteps: Int
    private var boost: Float = 1.0
    private(set) internal var correctionPlan: [MKExercise.Id:MKExercisePlan<Correction>] = [:]
    
    public init(round: Round, step: Step, maxDegree: Int = 1, maxSamples: Int = 2, maxCorrectionSteps: Int = 10) {
        linearPredictor = MKPolynomialFittingScalarPredictor(round: round, maxDegree: maxDegree, maxSamples: maxSamples)
        self.round = round
        self.step = step
        self.maxCorrectionSteps = maxCorrectionSteps
    }
    
    func mergeCoefficients(otherCoefficients: [MKExercise.Id:[Float]], otherSimpleScalars: [MKExercise.Id:Float]?, otherCorrectionPlan: [MKExercise.Id:NSData]) {
        linearPredictor.mergeCoefficients(otherCoefficients, otherSimpleScalars: otherSimpleScalars)
        for (nk, nv) in otherCorrectionPlan {
            if let newPlan = MKExercisePlan<Correction>.fromJsonFirst(nv, stateTransform: { ($0 as! Int) }) {
                correctionPlan[nk] = newPlan
            }
        }
    }
    
    // Implements MKScalarPredictor
    public func setBoost(boost: Float) {
        self.boost = boost
    }
    
    // Implements MKScalarPredictor
    public func trainPositional(trainingSet: [Double], forExerciseId exerciseId: MKExercise.Id) {
        let plan = correctionPlan[exerciseId] ?? MKExercisePlan<Correction>()

        if let predicted = linearPredictor.predictScalarForExerciseId(exerciseId, n: trainingSet.count - 1),
            let last = trainingSet.last {
                // compare the predicted value with the latest value
                // and get the corresponding correction (e.g. LittleMore)
                let c = correction(last, predicted: max(0, predicted), forExerciseId: exerciseId)
                // add this correction to the MarkovChain
                plan.insert(c)
        }
        // update the correction plan
        correctionPlan[exerciseId] = plan
        
        // update the linear regression coefficients
        linearPredictor.trainPositional(trainingSet, forExerciseId: exerciseId)
    }
    
    /// return the ``Correction`` corresponding to the error made on the predicted value
    /// by comparing the error to the weight increment for the given exercise
    private func correction(actual: Double, predicted: Double, forExerciseId exerciseId: MKExercise.Id) -> Correction {
        assert(actual > 0)
        assert(predicted > 0)
        
        // 10, 12
        
        let sign = (actual - predicted) >= 0 ? 1 : -1
        let c = (1..<maxCorrectionSteps)
            .map { actual - step(predicted, $0 * sign, exerciseId) }
            .enumerate()
            .minElement { l, r in
                return l.element < r.element
            }?
            .index
        
        return c ?? 0
//        let w = progression(exerciseId)
//        let c = Int(error / w)
//        if let m = maxCorrection {
//            // make sure c is in [-m,m]
//            return max(-m, min(m, c))
//        }
//        return c
    }
    
    // Implements MKScalarPredictor
    public func predictScalarForExerciseId(exerciseId: MKExercise.Id, n: Int) -> Double? {
        if let prediction = linearPredictor.predictScalarForExerciseId(exerciseId, n: n) {
            // get the correction for this prediction
            let correctedValue = correctionPlan[exerciseId]?.next.first.map {
                step(prediction, $0, exerciseId)
            } ?? prediction
            return round(Double(correctedValue), exerciseId)
        }
        return nil
    }
    
}