import Foundation
import SwiftyJSON
import MuvrKit

extension MRResistanceExerciseSession {
    
    func marshal() -> [String : AnyObject] {
        return ["startDate":startDate.marshal(), "intendedIntensity":intendedIntensity, "exerciseModel":exerciseModel.marshal(), "title":title]
    }

    static func unmarshal(json: JSON) -> MRResistanceExerciseSession {
        return MRResistanceExerciseSession(startDate: NSDate.unmarshal(json["startDate"].stringValue),
                                           intendedIntensity: json["intendedIntensity"].doubleValue,
                                           exerciseModel: MRExerciseModel.unmarshal(json["exerciseModel"]),
                                           title: json["title"].stringValue)
    }
    
}
