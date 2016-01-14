import Foundation

// TODO: Consider the const term
// TODO: Comments
// TODO: Integration
public class MKPolynomialFittingScalarPredictor : MKScalarPredictor {
    private(set) internal var coefficients: [Key:[Float]] = [:]
    private var boost: Float = 1.0
    private var simpleScalars: [Key:Float] = [:]
    private let exercisePropertySource: MKExercisePropertySource

    public typealias Key = MKExerciseId
    
    ///
    /// Merges the coefficients in this instance with ``otherCoefficients``. This is typically
    /// used to update the coefficients when the user arrives at a different location: users
    /// actually vary their weight selection depending on location.
    ///
    /// - parameter otherCoefficients: the new (typically loaded for a new location) coefficients
    ///
    public func merge(otherCoefficients: [Key:[Float]]) {
        for (nk, nv) in otherCoefficients {
            coefficients[nk] = nv
        }
    }
    
    public init(exercisePropertySource: MKExercisePropertySource) {
        self.exercisePropertySource = exercisePropertySource
    }
    
    private func roundValue(value: Float, forExerciseId exerciseId: Key) -> Float {
        for property in exercisePropertySource.exercisePropertiesForExerciseId(exerciseId) {
            switch property {
            case .WeightProgression(let minimum, let increment, let maximum):
                if value < minimum { return minimum }
                for var weight: Float = minimum; weight < maximum ?? 999; weight += increment {
                    let dcw = value - weight
                    let dnw = value - (weight + increment)
                    if dcw >= 0 && dnw <= 0 {
                        // value is in range
                        if abs(dcw) > abs(dnw) {
                            return weight + increment
                        } else {
                            return weight
                        }
                    }
                }
                return value
            }
        }
        return value
    }
    
    private func naiveCost(actual: [Float], predicted: [Float]) -> Float {
        return predicted.enumerate().reduce(0) { result, e in
            let (i, p) = e
            return result + abs(actual[i] - p)
        }
    }
    
    private func predictAndRound(x: Float, coefficients: [Float], forExerciseId exerciseId: Key) -> Float {
        let raw: Float = coefficients.enumerate().reduce(0) { (result, e) in
            let (n, c) = e
            return result + c * powf(x, Float(n))
        }
        return roundValue(raw * boost, forExerciseId: exerciseId)
    }
    
    public func setBoost(boost: Float) {
        self.boost = boost
    }
    
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
                NSLog("Trained \(bestCoefficients) for exercise \(exerciseId)")
                coefficients[exerciseId] = bestCoefficients
                simpleScalars[exerciseId] = nil
            }
        } else if let last = trainingSet.last {
            simpleScalars[exerciseId] = Float(last)
        }
    }
    
    public func predictWeightForExerciseId(exerciseId: MKExerciseId, n: Int) -> Double? {
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