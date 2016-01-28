import Foundation

public enum MarkovPredictionMode {
    case Raw
    case Inc
    case Mult
}

///
/// Implements the scalar predictor using markov chain
///
public class MKMarkovPredictor : MKScalarPredictor {
    public typealias Key = MKExercise.Id
    private(set) internal var weightPlan: [Key:MKExercisePlan<Float>] = [:]
    private(set) internal var simpleScalars: [Key:Float] = [:]
    
    private var boost: Float = 1.0
    
    private let mode: MarkovPredictionMode
    private let rounder: (Double, MKExercise.Id) -> Double
    
    public func mergeModel(otherWeightPlan: [Key:NSData], otherSimpleScalars: [Key:Float]?) {
        for (nk, nv) in otherWeightPlan {
            if let newPlan = MKExercisePlan<Float>.fromJsonFirst(nv, stateTransform: {element in Float(element as! String)}) {
                weightPlan[nk] = newPlan
            }
        }
        if let otherSimpleScalars = otherSimpleScalars {
            for (nk, nv) in otherSimpleScalars {
                simpleScalars[nk] = nv
            }
        }
    }
    
    public init(mode: MarkovPredictionMode = .Raw, round: ((Double, MKExercise.Id) -> Double)? = nil) {
        self.mode = mode
        if let round = round { self.rounder = round }
        else { self.rounder = { (value: Double, _:MKExercise.Id) in return value } }
    }
    
    // Implements MKScalarPredictor
    public func setBoost(boost: Float) {
        self.boost = boost
    }
    
    // Implements MKScalarPredictor
    public func trainPositional(trainingSet: [Double], forExerciseId exerciseId: Key) {
        // only add the last element to the plan (the previous elements are already added to the markov chain
        let plan = weightPlan[exerciseId] ?? MKExercisePlan<Float>()
        if let last = trainingSet.last {
            switch mode {
            case .Inc:  plan.insert(Float(simpleScalars[exerciseId].map { last - Double($0) } ?? 0.0))
            case .Mult: plan.insert(Float(simpleScalars[exerciseId].map { last / Double($0) } ?? 1.0))
            case .Raw:  plan.insert(Float(last))
            }
        }
        weightPlan[exerciseId] = plan
        if let last = trainingSet.last {
            simpleScalars[exerciseId] = Float(last)
        }
    }
    
    // Implements MKScalarPredictor
    public func predictScalarForExerciseId(exerciseId: Key, n: Int) -> Double? {
        if let nextValue = weightPlan[exerciseId]?.next.first {
            switch mode {
            case .Raw:  return Double(nextValue)
            case .Inc:  return simpleScalars[exerciseId].map { Double($0 + nextValue) }
            case .Mult: return simpleScalars[exerciseId].map { rounder(Double($0 * nextValue), exerciseId) }
            }
        }
        if let lastValue = simpleScalars[exerciseId] {
            return Double(lastValue)
        }
        return nil
    }
    
}