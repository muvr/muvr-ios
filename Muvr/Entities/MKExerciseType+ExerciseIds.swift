import Foundation
import MuvrKit

extension MKExerciseType {
    
    private static let resistanceTargeted = "resistanceTargeted"
    private static let resistanceWholeBody = "resistanceWholeBody"
    
    static func fromExerciseId(id: String) -> MKExerciseType? {
        let components = id.componentsSeparatedByString("/")
        if components.count < 3 { return nil }
        
        switch (components[0], components[1]) {
        case (resistanceTargeted, let muscleGroup):
            return MKMuscleGroup.fromString(muscleGroup).map { .ResistanceTargeted(muscleGroups: [$0]) }
        case (resistanceWholeBody, _): return .ResistanceWholeBody
        default: return nil
        }
    }
    
    var prefixes: [String] {
        switch self {
        // case .Cardio: return ["cardio/"]
        case .ResistanceTargeted(let muscleGroups): return muscleGroups.map { "\(MKExerciseType.resistanceTargeted)/\($0.prefix)" }
        case .ResistanceWholeBody: return ["\(MKExerciseType.resistanceTargeted)//" ]
        }
    }
    
    func containsExerciseId(id: MKExerciseId) -> Bool {
        for prefix in prefixes {
            if id.hasPrefix(prefix) { return true }
        }
        return false
    }
    
}

