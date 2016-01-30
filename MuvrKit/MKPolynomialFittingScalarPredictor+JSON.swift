import Foundation

public extension MKPolynomialFittingScalarPredictor {

    public var json: NSData {
        return try! NSJSONSerialization.dataWithJSONObject(["coefficients":coefficients, "simpleScalars":simpleScalars], options: [])
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
           let dict = json as? [String : AnyObject],
           let otherCoefficients = dict["coefficients"] as? [MKExercise.Id : [Float]],
           let simpleScalars = dict["simpleScalars"] as? [MKExercise.Id : Float]? {
            self.init(round: round, maxDegree: maxDegree, maxSamples: maxSamples)
            mergeCoefficients(otherCoefficients, otherSimpleScalars: simpleScalars)
        } else {
            return nil
        }
    }
    
}
