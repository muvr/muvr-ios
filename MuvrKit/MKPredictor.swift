import Foundation

public protocol MKPredictor {

    func predicAt<K where K : Hashable>(x: Int, forKey: K) -> Double
    
}
