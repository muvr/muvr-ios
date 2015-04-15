import Foundation

struct MRExerciseSessionPayload {
    var data: String
    
    static func empty() -> MRExerciseSessionPayload {
        return MRExerciseSessionPayload(data: "")
    }
}

extension MRExerciseSessionPayload {
    
    static func unmarshal(json: JSON) -> MRExerciseSessionPayload? {
        if json.isEmpty {
            return nil
        } else {
            return MRExerciseSessionPayload(data: json["data"].stringValue)
        }
    }
    
    func marshal() -> [String : AnyObject] {
        var params: [String : AnyObject] = ["data": data]
        return params
    }
}