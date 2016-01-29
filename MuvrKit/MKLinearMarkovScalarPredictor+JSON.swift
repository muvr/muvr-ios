extension MKLinearMarkovScalarPredictor {

    public var json: NSData {
        var planJson: [String: [String : AnyObject]] = [:]
        correctionPlan.forEach {(exerciseId, plan) in
            planJson[exerciseId] = plan.metadata {"\($0)"}
        }
        return try! NSJSONSerialization.dataWithJSONObject([
            "coefficients": linearPredictor.coefficients,
            "simpleScalars": linearPredictor.simpleScalars,
            "corrections": planJson
        ], options: [])
    }
    
    public func mergeJSON(data: NSData) {
        if let json = try? NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments),
            let dict = json as? [String : AnyObject],
            let otherCoefficients = dict["coefficients"] as? [MKExercise.Id : [Float]],
            let simpleScalars = dict["simpleScalars"] as? [MKExercise.Id : Float],
            let corrections = dict["corrections"] as? [String: NSData] {
                mergeCoefficients(otherCoefficients, otherSimpleScalars: simpleScalars, otherCorrectionPlan: corrections)
        }
    }
    
}