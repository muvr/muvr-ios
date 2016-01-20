import Foundation

///
/// Implements the scalar predictor using markov chain
///
public class MKMarkovPredictor : MKScalarPredictor {
    
    public typealias Key = MKExercise.Id
    private(set) internal var weightPlan: [Key:MKExercisePlan<Float>] = [:]
    private(set) internal var simpleScalars: [Key:Float] = [:]
    
    private var boost: Float = 1.0
    
    // Implements MKScalarPredictor
    public func setBoost(boost: Float) {
        self.boost = boost
    }
    
    // Implements MKScalarPredictor
    public func trainPositional(trainingSet: [Double], forExerciseId exerciseId: Key) {
        let plan = weightPlan[exerciseId] ?? MKExercisePlan<Float>()
        for element in trainingSet {
            plan.insert(Float(element))
        }
        weightPlan[exerciseId] = plan
        if let last = trainingSet.last {
            simpleScalars[exerciseId] = Float(last)
        }
    }
    
    // Implements MKScalarPredictor
    public func predictScalarForExerciseId(exerciseId: Key, n: Int) -> Double? {
        if let nextValue = weightPlan[exerciseId]?.next.first {
            return Double(nextValue)
        }
        if let lastValue = simpleScalars[exerciseId] {
            return Double(lastValue)
        }
        return nil
    }
    
}