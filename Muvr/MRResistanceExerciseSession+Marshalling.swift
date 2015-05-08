import Foundation

extension MRResistanceExerciseSession {
    
    func marshal() -> [String : AnyObject] {
        return ["startDate":startDate.marshal(), "properties":properties.marshal()]
    }

    static func unmarshal(json: JSON) -> MRResistanceExerciseSession {
        return MRResistanceExerciseSession(startDate: NSDate.unmarshal(json["startDate"].stringValue),
                                           properties: MRResistanceExerciseSessionProperties.unmarshal(json["properties"]))
    }
    
}
