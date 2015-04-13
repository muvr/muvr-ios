import Foundation

struct ExerciseSessionPayload {
    var data: String
    
    static func empty() -> ExerciseSessionPayload {
        return ExerciseSessionPayload(data: "")
    }
}

extension ExerciseSessionPayload {
    
    static func unmarshal(json: JSON) -> ExerciseSessionPayload? {
        if json.isEmpty {
            return nil
        } else {
            return ExerciseSessionPayload(data: json["data"].stringValue)
        }
    }
    
    func marshal() -> [String : AnyObject] {
        var params: [String : AnyObject] = ["data": data]
        return params
    }
}