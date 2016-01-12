import Foundation

///
/// Adds JSON serialization to MKMuscleGroup
///
extension MKMuscleGroup {
    
    ///
    /// JSON representation of this value
    ///
    var json: MKMuscleGroupJson {
        switch self {
        case .Arms: return "arms"
        case .Back: return "back"
        case .Chest: return "chest"
        case .Core:  return "core"
        case .Legs:  return "legs"
        case .Shoulders:  return "shoulders"
        }
    }
    
    ///
    /// Convert the ``json`` (AST) to an instance of MKMuscleGroup
    /// - parameter json: The JSON string
    /// - returns: MKMuscleGroup
    ///
    static func fromJson(json: MKMuscleGroupJson) -> MKMuscleGroup? {
        switch json {
        case "arms": return .Arms
        case "back": return .Back
        case "chest": return .Chest
        case "core": return .Core
        case "legs": return .Legs
        case "shoulders": return .Shoulders
        default: return nil
        }
    }
    
}

///
/// The muscle group json
///
public typealias MKMuscleGroupJson = String
