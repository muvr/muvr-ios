import Foundation

extension MRResistanceExercisePlan {
    
    static func unmarshal(json: JSON) -> MRResistanceExercisePlan {
        return MRResistanceExercisePlan(
            title: json["title"].string,
            intendedIntensity: json["intendedIntensity"].doubleValue,
            muscleGroupIds: json["muscleGroupIds"].arrayValue.map { $0.stringValue },
            exercises: json["exercises"].arrayValue.map(MRResistanceExercise.unmarshal)
        )
    }
    
    func marshal() -> [String : AnyObject] {
        var r: [String : AnyObject] = [
            "muscleGroupIds":muscleGroupIds,
            "exercises":exercises.map { $0.marshal() },
            "intendedIntensity":intendedIntensity
        ]
        if let x = title { r["title"] = x }
        return r
    }
    
}