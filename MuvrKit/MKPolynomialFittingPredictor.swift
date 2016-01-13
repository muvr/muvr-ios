import Foundation

public class MKPolynomialFittingPredictor<A where A : Hashable> : MKPredictor {
    public typealias K = A
    private var coefficients: [K:[Float]] = [:]
    
    public func train(x x: [Double], y: [Double], forKey key: K) {
        
    }
    
    public func predicAt(x: Int, forKey key: K) -> Double? {
        return 0
    }
    
}