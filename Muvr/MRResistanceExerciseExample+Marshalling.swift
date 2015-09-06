import Foundation

extension MRResistanceExercise {
    
    func marshal() -> [String : AnyObject] {
        var params: [String : AnyObject] = ["id": id]
        return params
    }
    
    static func unmarshal(json: JSON) -> MRResistanceExercise {
        return MRResistanceExercise(id: json["id"].stringValue)
    }
    
}

extension MRResistanceExerciseExample {
    
    func marshal() -> [String : AnyObject] {
        let jsonData = JSON(data: fusedSensorData, options: NSJSONReadingOptions.AllowFragments, error: nil)
        var params: [String : AnyObject] = [
            "classified":classified.map { $0.marshal() },
            "fusedSensorData":jsonData.object
        ]
        if let x = correct { params["correct"] = x.marshal() }
        return params
    }
    
    static func unmarshal(json: JSON) -> MRResistanceExerciseExample {
        let correct = MRClassifiedResistanceExercise.unmarshal(json["correct"])
        let fsd = json["fusedSensorData"].rawData(options: NSJSONWritingOptions.allZeros, error: nil)!
        
        return MRResistanceExerciseExample(
            classified: json["classified"].arrayValue.map(MRClassifiedResistanceExercise.unmarshal),
            correct: correct,
            fusedSensorData: fsd)
    }
    
}
