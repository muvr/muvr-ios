import Foundation

///
/// Adds JSON serialization to MKMuscleGroup
///
extension MKMuscleGroup {
    
    ///
    /// JSON representation of this value
    ///
    var json: AnyObject {
        switch self {
        case .Arms: return try! NSJSONSerialization.dataWithJSONObject("arms", options: [])
        case .Back: return try! NSJSONSerialization.dataWithJSONObject("back", options: [])
        case .Chest: return try! NSJSONSerialization.dataWithJSONObject("chest", options: [])
        case .Core:  return try! NSJSONSerialization.dataWithJSONObject("core", options: [])
        case .Legs:  return try! NSJSONSerialization.dataWithJSONObject("legs", options: [])
        case .Shoulders:  return try! NSJSONSerialization.dataWithJSONObject("shoulders", options: [])
        }
    }
    
    ///
    /// Convert the ``json`` (AST) to an instance of MKMuscleGroup
    /// - parameter json: The JSON string
    /// - returns: MKMuscleGroup 
    ///
    static func fromJson(json: AnyObject) -> MKMuscleGroup? {
        if let s = json as? String {
            switch s {
            case "arms": return .Arms
            case "back": return .Back
            case "chest": return .Chest
            case "core": return .Core
            case "legs": return .Legs
            case "shoulders": return .Shoulders
            default: return nil
            }
        }
        return nil
    }
    
}
