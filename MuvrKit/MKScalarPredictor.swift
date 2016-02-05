import Foundation

///
/// Provides simple predictions
///
public protocol MKScalarPredictor {
    
    /// The JSON representation of the predictor
    var metadata: [String : AnyObject] { get }
    
    /// Initialize this predictor with the given metadata
    func mergeMetadata(metadata: [String : AnyObject]) throws
    
    ///
    /// Trains the predictor with the given ``trainingSet`` and ``exerciseId``
    /// - parameter trainingSet: the training set
    /// - parameter exerciseId: the exercise id
    ///
    func trainPositional(trainingSet: [Double], forExerciseId exerciseId: MKExercise.Id)
    
    ///
    /// Returns the scalar prediction for the ``exerciseId``
    /// - parameter exerciseId: the exercise id
    /// - parameter n: the exercise number, starting at 0
    /// - returns: the predicted weight
    ///
    func predictScalarForExerciseId(exerciseId: MKExercise.Id, n: Int) -> Double?
    
}

public extension MKScalarPredictor {

    /// The JSON representation of the predictor
    var json: NSData {
        get {
            return try! NSJSONSerialization.dataWithJSONObject(self.metadata, options: [])
        }
    }

}

enum MKScalarPredictorError: ErrorType {
    case InitialisationError
}
