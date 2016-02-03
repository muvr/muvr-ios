import Foundation

extension MKLinearRegressionPredictor {

    /// The JSON representation of the predictor
    public var metadata: [String : AnyObject] {
        return [
            "predictor": predictor.metadata,
            "coefficients": coefficients
        ]
    }
    
    /// create new instance from the JSON data
    public convenience init?(fromJson json: NSData, predictor: MKScalarPredictor, round: Round, degree: Int) {
        if let json = try? NSJSONSerialization.JSONObjectWithData(json, options: NSJSONReadingOptions.AllowFragments),
            let dict = json as? [String : AnyObject] {
                self.init(predictor: predictor, round: round, degree: degree)
                do { try self.mergeMetadata(dict) } catch { return nil }
        } else {
            return nil
        }
        
    }
    
}