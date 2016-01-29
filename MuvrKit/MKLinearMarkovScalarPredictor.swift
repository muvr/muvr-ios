public class MKLinearMarkovScalarPredictor : MKScalarPredictor {
    
    public typealias Round = (Double, MKExercise.Id) -> Double
    /// Return the value of a "single" increment for a given exercise
    public typealias Progression = (MKExercise.Id) -> Double
    
    typealias Correction = Int
    
    internal let linearPredictor: MKPolynomialFittingScalarPredictor
    private let round: Round
    private let progression: Progression
    private let maxCorrection: Correction?
    private var boost: Float = 1.0
    private(set) internal var correctionPlan: [MKExercise.Id:MKExercisePlan<Correction>] = [:]
    
    public init(round: Round, progression: Progression, maxDegree: Int = 1, maxSamples: Int=2, maxCorrectionSteps: Int? = nil) {
        linearPredictor = MKPolynomialFittingScalarPredictor(round: round, maxDegree: maxDegree, maxSamples: maxSamples)
        self.round = round
        self.progression = progression
        self.maxCorrection = maxCorrectionSteps
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
                let c = correction(last - predicted, forExerciseId: exerciseId)
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
    private func correction(error: Double, forExerciseId exerciseId: MKExercise.Id) -> Correction {
        let w = progression(exerciseId)
        let c = Int(error / w)
        if let m = maxCorrection {
            // make sure c is in [-m,m]
            return max(-m, min(m, c))
        }
        return c
    }
    
    // Implements MKScalarPredictor
    public func predictScalarForExerciseId(exerciseId: MKExercise.Id, n: Int) -> Double? {
        if let prediction = linearPredictor.predictScalarForExerciseId(exerciseId, n: n) {
            // get the correction for this prediction
            let correction = correctionPlan[exerciseId]?.next.first.map {
                // and convert it to a weight value
                Double($0) * progression(exerciseId)
            } ?? 0
            return round(Double(prediction) + correction, exerciseId)
        }
        return nil
    }
    
}