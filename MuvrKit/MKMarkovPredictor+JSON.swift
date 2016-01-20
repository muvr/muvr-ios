import Foundation

public extension MKMarkovPredictor {
    
    public var json: NSData {
        var planJson: [String: [String : AnyObject]] = [:]
        weightPlan.forEach {(exerciseId, weightPlan) in
            planJson[exerciseId] = weightPlan.metadata {"\($0)"}
        }
        NSLog("\n\n\n\njson = \(planJson)")
        return try! NSJSONSerialization.dataWithJSONObject(["weightPlan": planJson, "simpleScalars":simpleScalars], options: [])
    }
    
    public func mergeJSON(data: NSData) {
        if let json = try? NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments),
            let dict = json as? [String : AnyObject],
            let newWeightPlan = dict["weightPlan"] as? [String: NSData],
            let newSimpleScalars = dict["simpleScalars"] as? [MKExercise.Id : Float]? {
                mergeModel(newWeightPlan, otherSimpleScalars: newSimpleScalars)
        }
    }
}
