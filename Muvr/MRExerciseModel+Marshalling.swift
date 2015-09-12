import Foundation
import SwiftyJSON

extension MRExerciseModel {
    
    /// Load MRMuscleGroup from JSON
    static func unmarshal(json: JSON) -> MRExerciseModel {
        return MRExerciseModel(
            id: json["id"].stringValue,
            title: json["title"].stringValue,
            exercises: json["exercises"].arrayValue.map { $0.stringValue }
        )
    }
    
    func marshal() -> [String : AnyObject] {
        return ["id":id, "title":title, "exercises":exercises]
    }
    
}
