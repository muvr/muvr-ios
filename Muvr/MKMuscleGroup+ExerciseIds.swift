import Foundation
import MuvrKit

extension MKMuscleGroup {
    
    static func fromString(s: String) -> MKMuscleGroup? {
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

    /// Defines the exercise id prefix
    var prefix: String {
        switch self {
        case .Arms: return "arms"
        case .Back: return "back"
        case .Chest: return "chest"
        case .Core: return "core"
        case .Legs: return "legs"
        case .Shoulders: return "shoulders"
        }
    }
    
}
