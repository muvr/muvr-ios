import Foundation

///
/// Provides simple predictions
///
public protocol MKPredictor {
    
    /// The key key type
    typealias K : Hashable
    
    ///
    /// Predict the value at the (presumably positional) value ``x`` for some key
    /// - parameter x: the independent value
    /// - parameter key: the key value
    /// - returns: the prediction
    ///
    func predicAt(x: Int, forKey key: K) -> Double?
    
}
