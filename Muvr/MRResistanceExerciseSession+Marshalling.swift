import Foundation

extension MRResistanceExerciseSession {
    
    func marshal() -> [String : AnyObject] {
        return ["startDate":startDate.marshal(), "intendedIntensity":intendedIntensity, "muscleGroupIds":muscleGroupIds, "title":title]
    }

    static func unmarshal(json: JSON) -> MRResistanceExerciseSession {
        return MRResistanceExerciseSession(startDate: NSDate.unmarshal(json["startDate"].stringValue),
                                           intendedIntensity: json["intendedIntensity"].doubleValue,
                                           muscleGroupIds: json["muscleGroupIds"].arrayValue.map { $0.stringValue },
                                           title: json["title"].stringValue)
    }
    
}
