public class MKLinearMarkovScalarPredictor : MKScalarPredictor {
    
    enum Correction: Int {
        case MuchLess = -2
        case LittleLess = -1
        case None = 0
        case LittleMore = 1
        case MuchMore = 2
        
    }

    public typealias Round = (Double, MKExercise.Id) -> Double
    public typealias Props = (MKExercise.Id) -> [MKExerciseProperty]
    
    internal let linearPredictor: MKPolynomialFittingScalarPredictor
    private let round: Round
    private let props: Props
    private var boost: Float = 1.0
    private(set) internal var correctionPlan: [MKExercise.Id:MKExercisePlan<Correction>] = [:]
    
    public init(round: Round, props: Props, maxDegree: Int = 1, maxSamples: Int=2) {
        linearPredictor = MKPolynomialFittingScalarPredictor(round: round, maxDegree: maxDegree, maxSamples: maxSamples)
        self.round = round
        self.props = props
    }
    
    func mergeCoefficients(otherCoefficients: [MKExercise.Id:[Float]], otherSimpleScalars: [MKExercise.Id:Float]?, otherCorrectionPlan: [MKExercise.Id:NSData]) {
        linearPredictor.mergeCoefficients(otherCoefficients, otherSimpleScalars: otherSimpleScalars)
        for (nk, nv) in otherCorrectionPlan {
            if let newPlan = MKExercisePlan<Correction>.fromJsonFirst(nv, stateTransform: {element in Correction(rawValue: element as! Int)}) {
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
        let w = weightProgression(forExerciseId: exerciseId)
        switch abs(error / w) {
        case 0..<1: return .None
        case 1..<2: return error > 0 ? .LittleMore : .LittleLess
        default: return error > 0 ? .MuchMore : .MuchLess
        }
    }
    
    /// return the weight increment of a given exercise
    private func weightProgression(forExerciseId exerciseId: MKExercise.Id) -> Double {
        for case MKExerciseProperty.WeightProgression(_, let step, _) in props(exerciseId) {
            return step
        }
        return 1
    }
    
    // Implements MKScalarPredictor
    public func predictScalarForExerciseId(exerciseId: MKExercise.Id, n: Int) -> Double? {
        if let prediction = linearPredictor.predictScalarForExerciseId(exerciseId, n: n) {
            // get the correction for this prediction
            let correction = correctionPlan[exerciseId]?.next.first.map {
                // and convert it to a weight value
                Double($0.rawValue) * weightProgression(forExerciseId: exerciseId)
            } ?? 0
            return round(Double(prediction) + correction, exerciseId)
        }
        return nil
    }
    
}