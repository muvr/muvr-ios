import Foundation

extension MRExercise {
    
    func marshal() -> [String : AnyObject] {
        return ["id":id, "title":title]
    }
    
    static func unmarshal(json: JSON) -> MRExercise {
        return MRExercise(id: json["id"].stringValue, title: json["title"].stringValue)
    }
    
}