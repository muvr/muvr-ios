import Foundation

extension MRClassifiedExercise {
    
    func marshal() -> [String : AnyObject] {
        var params: [String : AnyObject] = ["exercise": exercise, "confidence": confidence]
        if intensity != nil { params["intensity"] = intensity.doubleValue }
        if repetitions != nil { params["repetitions"] = repetitions.integerValue }
        if weight != nil { params["weight"] = weight.doubleValue }
        return params
    }
    
}

extension MRClassifiedExerciseSet {
    
    func marshal() -> [String : AnyObject] {
        return ["sets":sets.map { $0.marshal() }]
    }
    
}

extension MRExerciseExample {
    
    func marshal() -> [String : AnyObject] {
        let jsonData = JSON(data: fusedSensorData, options: NSJSONReadingOptions.AllowFragments, error: nil)
        var params: [String : AnyObject] = [
            "classified":classified.map { $0.marshal() },
            "fusedSensorData":jsonData.object
        ]
        if let x = correct { params["correct"] = x.marshal() }
        return params
    }
    
}
