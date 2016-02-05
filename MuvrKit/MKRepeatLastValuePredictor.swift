import Foundation

///
/// Implements the scalar predictor and repeat the last value
///
public class MKRepeatLastValuePredictor: MKScalarPredictor  {
    
    public typealias Round = (Double, MKExercise.Id) -> Double
    public typealias Key = MKExercise.Id
    
    private var lastValues: [Key : Double] = [:]
    
    public init() { }
    
    /// The JSON representation of the predictor
    public var metadata: [String : AnyObject] { return lastValues }
    
    /// Initialize this predictor with the given metadata
    public func mergeMetadata(metadata: [String : AnyObject]) throws {
        guard let values = metadata as? [String: Double] else { throw MKScalarPredictorError.InitialisationError }
        lastValues = values
    }
    
    ///
    /// Trains the predictor with the given ``trainingSet`` and ``exerciseId``
    /// - parameter trainingSet: the training set
    /// - parameter exerciseId: the exercise id
    ///
    public func trainPositional(trainingSet: [Double], forExerciseId exerciseId: MKExercise.Id) {
        guard let last = trainingSet.last else { return }
        lastValues[exerciseId] = last
    }
    
    ///
    /// Returns the scalar prediction for the ``exerciseId``
    /// - parameter exerciseId: the exercise id
    /// - parameter n: the exercise number, starting at 0
    /// - returns: the predicted weight
    ///
    public func predictScalarForExerciseId(exerciseId: MKExercise.Id, n: Int) -> Double? {
        return lastValues[exerciseId]
    }
    
    public convenience init?(fromJSON data: NSData) {
        if let json = try? NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments),
            let dict = json as? [String : AnyObject] {
                self.init()
                do { try mergeMetadata(dict) } catch { return nil }
        } else {
            return nil
        }
    }

    
}