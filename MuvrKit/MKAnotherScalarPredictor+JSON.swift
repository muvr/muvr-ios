import Foundation

extension MKAnotherScalarPredictor {

    /// create new instance from the JSON data
    public convenience init?(fromJson json: NSData, makePredictor: Predictor) {
        if let json = try? NSJSONSerialization.JSONObjectWithData(json, options: NSJSONReadingOptions.AllowFragments),
            let dict = json as? [String : AnyObject] {
                self.init(makePredictor: makePredictor)
                do { try self.mergeMetadata(dict) } catch { return nil }
        } else {
            return nil
        }
    }
    
    /// The JSON representation of the predictor
    public var metadata: [String : AnyObject] {
        let metadata: [String:AnyObject] = [
            "defaultPredictor": defaultPredictor.metadata,
            "predictors": predictors.map { $0.metadata },
            "trainingSets": trainingSets
        ]
        return metadata
    }
    
}