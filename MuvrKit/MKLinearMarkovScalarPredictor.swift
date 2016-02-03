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
    private let maxSamples: Int
    private var boost: Float = 1.0
    private(set) internal var correctionPlan: [MKExercise.Id:MKExercisePlan<Correction>] = [:]
    
    public init(round: Round, step: Step, maxDegree: Int = 1, maxSamples: Int = 2, maxCorrectionSteps: Int = 100) {
        linearPredictor = MKPolynomialFittingScalarPredictor(round: round, maxDegree: maxDegree, maxSamples: maxSamples)
        self.round = round
        self.step = step
        self.maxSamples = maxSamples
        self.maxCorrectionSteps = maxCorrectionSteps
    }
    
    func mergeCoefficients(otherCoefficients: [MKExercise.Id:[Float]], otherSimpleScalars: [MKExercise.Id:Float]?, otherCorrectionPlan: [MKExercise.Id:[String : AnyObject]]) {
        linearPredictor.mergeCoefficients(otherCoefficients, otherSimpleScalars: otherSimpleScalars)
        for (nk, nv) in otherCorrectionPlan {
            if let newPlan = MKExercisePlan<Correction>.fromMetadataFirst(nv, stateTransform: { Int($0 as! String) }) {
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
        print("Training \(exerciseId) over \(trainingSet)")
        // update the linear regression coefficients
        linearPredictor.trainPositional(trainingSet, forExerciseId: exerciseId)

        let plan = MKExercisePlan<Correction>()
        for (index, actual) in trainingSet.suffix(maxSamples).enumerate() {
            if let predicted = linearPredictor.predictScalarForExerciseId(exerciseId, n: index) {
                // compare the predicted value with the latest value
                let c = correction(actual, predicted: max(0, predicted), forExerciseId: exerciseId)
                // add this correction to the MarkovChain
                plan.insert(c)
                if actual != predicted {
                    print("At \(index): \(actual) vs \(predicted) => diff = \(actual - predicted) => correction = \(c)")
                }
            }
        }
        
        correctionPlan[exerciseId] = plan
    }
    
    /// return the ``Correction`` corresponding to the error made on the predicted value
    /// by comparing the error to the weight increment for the given exercise
    private func correction(actual: Double, predicted: Double, forExerciseId exerciseId: MKExercise.Id) -> Correction {
        assert(actual >= 0)
        assert(predicted >= 0)
        
        if abs(actual - predicted) < 0.0001 { return 0 }
        
        // 10, 12
        
        let sign = (actual - predicted) >= 0 ? 1 : -1
        let x = ((1..<maxCorrectionSteps+1)
            .map { actual - step(predicted, $0 * sign, exerciseId) })
        print("Sign \(sign)")
        print("Corrections \(x)")

        if let c = (x.enumerate()
            .minElement { l, r in
                let lv = abs(l.element)
                let rv = abs(r.element)
                if lv == rv {
                    return l.index < r.index
                }
                return lv < rv }?
            .index) {
            return (c + 1) * sign
        }
        return 0

//        if let c = ((1..<maxCorrectionSteps)
//            .map { actual - step(predicted, $0 * sign, exerciseId) }
//            .enumerate()
//            .minElement { l, r in return l.element < r.element }?
//            .index) {
//            return c * sign
//        }
//        
//        return 0
    }
    
    public func correctScalarForExerciseId(exerciseId: MKExercise.Id, n: Int, actual: Double) {
        // noop
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