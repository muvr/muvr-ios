import Foundation

extension NSUUID {
    
    static func unmarshal(json: JSON) -> NSUUID {
        return NSUUID(UUIDString: json.stringValue)!
    }
    
}