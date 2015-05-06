import Foundation

extension MRResistanceExerciseSessionProperties {
    
    func marshal() -> [String : AnyObject] {
        return ["intendedIntensity":intendedIntensity, "muscleGroupIds":muscleGroupIds]
    }
    
    static func unmarshal(json: JSON) -> MRResistanceExerciseSessionProperties {
        return MRResistanceExerciseSessionProperties(
            intendedIntensity: json["intendedIntensity"].doubleValue,
            muscleGroupIds: json["muscleGroupIds"].arrayValue.map { $0.stringValue })
    }
    
}