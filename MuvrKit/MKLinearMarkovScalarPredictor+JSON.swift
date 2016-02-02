extension MKLinearMarkovScalarPredictor {

    public var metadata: [String : AnyObject] {
        var planJson: [String: [String : AnyObject]] = [:]
        correctionPlan.forEach {(exerciseId, plan) in
            planJson[exerciseId] = plan.metadata {"\($0)"}
        }
        return [
            "coefficients": linearPredictor.coefficients,
            "simpleScalars": linearPredictor.simpleScalars,
            "corrections": planJson
        ]
    }
    
    public convenience init?(fromJSON data: NSData, round: Round, step: Step, maxDegree: Int = 1, maxSamples: Int = 2, maxCorrectionSteps: Int = 10) {
        if let json = try? NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments),
            let dict = json as? [String : AnyObject] {
            self.init(round: round, step: step, maxDegree: maxDegree, maxSamples: maxSamples, maxCorrectionSteps: maxCorrectionSteps)
                do { try self.mergeMetadata(dict) } catch { return nil }
        } else {
            return nil
        }
    }
    
    public func mergeMetadata(metadata: [String : AnyObject]) throws {
        if let otherCoefficients = metadata["coefficients"] as? [MKExercise.Id : [Float]],
            let simpleScalars = metadata["simpleScalars"] as? [MKExercise.Id : Float],
            let corrections = metadata["corrections"] as? [String: [String : AnyObject]] {
            mergeCoefficients(otherCoefficients, otherSimpleScalars: simpleScalars, otherCorrectionPlan: corrections)
        } else {
            throw MKScalarPredictorError.InitialisationError
        }
    }
    
}