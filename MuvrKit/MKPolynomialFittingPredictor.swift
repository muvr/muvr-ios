import Foundation

// TODO: Remove the const term
// TODO: Comments
// TODO: Integration
public class MKPolynomialFittingPredictor<A where A : Hashable> : MKPredictor {
    private var coefficients: [K:[Float]] = [:]
    private let round: RoundForKeyAndValue!

    public typealias K = A
    public typealias RoundForKeyAndValue = (K, Float) -> Float
    public typealias DistinctValuesForKey = K -> [Float]?

    public init() {
        round = MKPolynomialFittingPredictor.identityRound
    }
    
    public init(round: RoundForKeyAndValue) {
        self.round = round
    }
    
    public init(distinctValuesForKey: DistinctValuesForKey) {
        self.round = { (key, value) in
            if let distinctValues = distinctValuesForKey(key) {
                let differences: [Float] = distinctValues.map { abs($0 - value) }
                if let firstDifference = differences.first {
                    let (i, _) = differences.enumerate().reduce((0, firstDifference)) { result, element in
                        let (_, bestDifference) = result
                        let (currentIndex, currentDifference) = element
                        if bestDifference > currentDifference {
                            return (currentIndex, currentDifference)
                        }
                        return result
                    }
                    return distinctValues[i]
                }
            }
            return value
        }
    }
    
    private static func identityRound(_: K, x: Float) -> Float {
        return x
    }
    
    private func naiveCost(actual: [Float], predicted: [Float]) -> Float {
        return predicted.enumerate().reduce(0) { result, e in
            let (i, p) = e
            return result + abs(actual[i] - p)
        }
    }
    
    private func predictAndRound(x: Float, coefficients: [Float], forKey key: K) -> Float {
        let raw: Float = coefficients.enumerate().reduce(0) { (result, e) in
            let (n, c) = e
            return result + c * powf(x, Float(n))
        }
        return round(key, raw)
    }
    
    public func trainPositional(trainingSet: [Double], forKey key: K) throws {
        let x = trainingSet.enumerate().map { i, _ in return Float(i) }
        let y = trainingSet.map { Float($0) }

        var best: (Float, [Float])?
        for degree in 1..<min(trainingSet.count, 15) {
            if let coefficients = try? MKPolynomialFitter.fit(x: x, y: y, degree: degree) {
                let cost = naiveCost(y, predicted: x.map { predictAndRound($0, coefficients: coefficients, forKey: key) })
                if let (bestCost, _) = best {
                    if bestCost > cost { best = (cost, coefficients) }
                } else {
                    best = (cost, coefficients)
                }
            }
        }
        
        coefficients[key] = best!.1
    }
    
    public func predicAt(x: Int, forKey key: K) -> Double? {
        return coefficients[key].map { Double(predictAndRound(Float(x), coefficients: $0, forKey: key)) }
    }
    
}