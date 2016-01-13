import Foundation

public class MKPolynomialFittingPredictor<A where A : Hashable> : MKPredictor {
    public typealias K = A
    private var coefficients: [K:[Float]] = [:]
    
    public func trainPositional(x x: [Int], y: [Double], forKey key: K) throws {
        let c = try MKPolynomialFitter.fit(x: x.map { Float($0) }, y: y.map { Float($0) }, degree: 5)
        coefficients[key] = c
    }
    
    public func predicAt(x: Int, forKey key: K) -> Double? {
        if let coefficients = coefficients[key] {
            
        }
        return 0
    }
    
}