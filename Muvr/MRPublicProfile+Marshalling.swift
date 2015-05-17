import Foundation

extension MRPublicProfile {

    static func unmarshal(json: JSON) -> MRPublicProfile? {
        if json.isEmpty {
            return nil
        } else {
            return MRPublicProfile(firstName: json["firstName"].stringValue,
                lastName: json["lastName"].stringValue,
                weight: json["weight"].int,
                age: json["age"].int)
        }
    }
    
    func marshal() -> [String : AnyObject] {
        var params: [String : AnyObject] = ["firstName": firstName, "lastName": lastName]
        if let x = age { params["age"] = x }
        if let x = weight { params["weight"] = x }
        
        return params
    }

}
