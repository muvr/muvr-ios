import Foundation
import SwiftyJSON
import MuvrKit

extension MKExerciseModel {
    
    /// Load MRMuscleGroup from JSON
    static func unmarshal(json: JSON) -> MKExerciseModel {
        return MKExerciseModel(
            id: json["id"].stringValue,
            title: json["title"].stringValue,
            exerciseIds: json["exercises"].arrayValue.map { $0.stringValue }
        )
    }
    
    func marshal() -> [String : AnyObject] {
        return ["id":id, "title":title, "exercises":exerciseIds]
    }
    
}
