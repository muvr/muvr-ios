import Foundation

extension MRResistanceExercise {
    
    func marshal() -> [String : AnyObject] {
        let params: [String : AnyObject] = ["id": id]
        return params
    }
    
    static func unmarshal(json: JSON) -> MRResistanceExercise {
        return MRResistanceExercise(id: json["id"].stringValue)
    }
    
}

extension MRResistanceExerciseExample {
    
    func marshal() -> [String : AnyObject] {
        var params: [String : AnyObject] = [
            "classified":classified.map { $0.marshal() }
        ]
        if let x = correct { params["correct"] = x.marshal() }
        return params
    }
    
    static func unmarshal(json: JSON) -> MRResistanceExerciseExample {
        let correct = MRClassifiedResistanceExercise.unmarshal(json["correct"])
        
        return MRResistanceExerciseExample(
            classified: json["classified"].arrayValue.map(MRClassifiedResistanceExercise.unmarshal),
            correct: correct)
    }
    
}
