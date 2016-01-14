import Foundation

///
/// Provides simple predictions
///
public protocol MKScalarPredictor {
    
    ///
    /// Trains the predictor with the given ``trainingSet`` and ``exerciseId``
    /// - parameter trainingSet: the training set
    /// - parameter exerciseId: the exercise id
    ///
    func trainPositional(trainingSet: [Double], forExerciseId exerciseId: MKExerciseId)
    
    ///
    /// Returns the weight prediction for the ``n`` the instance of the ``exerciseId``
    /// - parameter exerciseId: the exercise id
    /// - parameter n: the exercise number, starting at 0
    /// - returns: the predicted weight
    ///
    func predictWeightForExerciseId(exerciseId: MKExerciseId, n: Int) -> Double?
    
}
