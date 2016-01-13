import Foundation

///
/// Base class for the predictor
///
public class MKPredictorXXX<A> {
    private let coefficients: [Float]
    
    internal init(coefficients: [Float]) {
        self.coefficients = coefficients
    }
    
    ///
    /// Returns a predictor whose independent values are derived from the position of 
    /// the elements in the ``trainingSet``. The training set is mapped over ``extractor``.
    /// The returned predictor can be used to predict some number of future elements
    /// based on the training set.
    ///
    /// - parameter trainingSet: the training set
    /// - parameter extractor: the function that maps ``A`` to ``Float``
    /// - returns: the trained predictor
    ///
    public static func positionalFromTrainingSet<A>(trainingSet: [A], extractor: A -> Float) throws -> MKPositionalPredictor<A> {
        let x = trainingSet.enumerate().map { i, _ in return Float(i) }
        let y = trainingSet.map(extractor)
        let coefficients = try MKPolynomialFitter.fit(x: x, y: y, degree: 5)
        return MKPositionalPredictor<A>(coefficients: coefficients, lastPosition: trainingSet.count)
    }
    
    ///
    /// Predicts the value at some ``x``.
    /// - parameter x: the independent value
    /// - returns: the predicted value
    ///
    public func predictAt(x: Float) -> Float {
        return coefficients.enumerate().reduce(0) { (result, e) in
            let (n, c) = e
            return result + c * powf(x, Float(n))
        }
    }
    
}

///
/// Predictor that can predict future elements based on their position
///
public class MKPositionalPredictor<A> : MKPredictorXXX<A> {
    private let lastPosition: Int
    
    internal init(coefficients: [Float], lastPosition: Int) {
        self.lastPosition = lastPosition
        super.init(coefficients: coefficients)
    }
    
    ///
    /// Predicts the next ``count`` values
    /// - parameter count: how many values to predict
    ///
    public func predictNext(count: Int) -> [Float] {
        return (0..<count).map { i in
            let x = Float(i + lastPosition)
            return predictAt(x)
        }
    }
    
}