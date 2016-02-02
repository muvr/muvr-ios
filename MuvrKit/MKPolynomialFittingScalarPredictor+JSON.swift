import Foundation

public extension MKPolynomialFittingScalarPredictor {

    public var metadata: [String : AnyObject] {
        return ["coefficients":coefficients, "simpleScalars":simpleScalars]
    }
    
//    public func mergeJSON(data: NSData) {
//        if let json = try? NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments),
//           let dict = json as? [String : AnyObject],
//           let otherCoefficients = dict["coefficients"] as? [MKExercise.Id : [Float]],
//           let simpleScalars = dict["simpleScalars"] as? [MKExercise.Id : Float]? {
//            mergeCoefficients(otherCoefficients, otherSimpleScalars: simpleScalars)
//        }
//    }
    
    public convenience init?(fromJSON data: NSData, round: Round, maxDegree: Int = 15, maxSamples: Int? = nil) {
        if let json = try? NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments),
            let dict = json as? [String : AnyObject] {
                self.init(round: round, maxDegree: maxDegree, maxSamples: maxSamples)
                do { try mergeMetadata(dict) } catch { return nil }
        } else {
            return nil
        }
    }
    
    public func mergeMetadata(metadata: [String : AnyObject]) throws {
        if let otherCoefficients = metadata["coefficients"] as? [MKExercise.Id : [Float]],
           let simpleScalars = metadata["simpleScalars"] as? [MKExercise.Id : Float]? {
            mergeCoefficients(otherCoefficients, otherSimpleScalars: simpleScalars)
        } else {
            throw MKScalarPredictorError.InitialisationError
        }
    }
    
}
