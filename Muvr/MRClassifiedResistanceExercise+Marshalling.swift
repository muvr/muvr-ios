import Foundation

extension MRClassifiedResistanceExercise {
    
    func marshal() -> [String : AnyObject] {
        var params: [String : AnyObject] = ["resistanceExercise":resistanceExercise.marshal(), "confidence":confidence]
        if let x = intensity { params["intensity"] = x }
        if let x = weight { params["weight"] = x }
        if let x = repetitions { params["repetitions"] = x }
        return params
    }
    
    static func unmarshal(json: JSON) -> MRClassifiedResistanceExercise {
        return MRClassifiedResistanceExercise(resistanceExercise: MRResistanceExercise.unmarshal(json["resistanceExercise"]),
            repetitions: json["repetitions"].number,
            weight: json["weight"].number, intensity: json["intensity"].number, andConfidence: json["confidence"].doubleValue)
    }
    
}