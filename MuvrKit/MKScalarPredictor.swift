import Foundation

///
/// Provides simple predictions
///
public protocol MKScalarPredictor {
    
    /// The JSON representation of the predictor
    var json: NSData { get }
    
    ///
    /// Trains the predictor with the given ``trainingSet`` and ``exerciseId``
    /// - parameter trainingSet: the training set
    /// - parameter exerciseId: the exercise id
    ///
    func trainPositional(trainingSet: [Double], forExerciseId exerciseId: MKExercise.Id)
    
    ///
    /// Returns the scalar prediction for the ``n`` the instance of the ``exerciseId``
    /// - parameter exerciseId: the exercise id
    /// - parameter n: the exercise number, starting at 0
    /// - returns: the predicted weight
    ///
    func predictScalarForExerciseId(exerciseId: MKExercise.Id, n: Int) -> Double?
 
    ///
    /// Sets the correct prediction for exerciseId at n
    /// - parameter exerciseId: the exercise id
    /// - parameter n: the exercise number, starting at 0
    /// - parameter actual: the actual value
    ///
    func correctScalarForExerciseId(exerciseId: MKExercise.Id, n: Int, actual: Double)
    
    ///
    /// Sets the boosting function to "motivate the headcounts"
    /// - parameter boost: the multiplier, typically close to 1.0
    ///
    func setBoost(boost: Float)
    
}
