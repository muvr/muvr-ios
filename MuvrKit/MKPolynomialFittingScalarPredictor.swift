import Foundation

// TODO: Consider the const term
// TODO: Comments
// TODO: Integration
public class MKPolynomialFittingScalarPredictor : MKScalarPredictor {
    private(set) internal var coefficients: [Key:[Float]] = [:]
    private let exercisePropertySource: MKExercisePropertySource

    public typealias Key = MKExerciseId

    init(coefficients: [Key:[Float]], exercisePropertySource: MKExercisePropertySource) {
        self.coefficients = coefficients
        self.exercisePropertySource = exercisePropertySource
    }
    
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
        return roundValue(raw, forExerciseId: exerciseId)
    }
    
    public func trainPositional(trainingSet: [Double], forExerciseId exerciseId: Key) throws {
        let x = trainingSet.enumerate().map { i, _ in return Float(i) }
        let y = trainingSet.map { Float($0) }

        var best: (Float, [Float])?
        for degree in 1..<min(trainingSet.count, 15) {
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
        
        coefficients[exerciseId] = best!.1
    }
    
    public func predictWeightForExerciseId(exerciseId: MKExerciseId, n: Int) -> Double? {
        return coefficients[exerciseId].map { Double(predictAndRound(Float(n), coefficients: $0, forExerciseId: exerciseId)) }
    }
    
}