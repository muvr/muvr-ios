import Foundation
import MuvrKit

extension MKExerciseType {
    
    private static let resistanceTargeted = "resistanceTargeted"
    private static let resistanceWholeBody = "resistanceWholeBody"
    
    ///
    /// Parses the given ``exerciseId`` to ``MKExerciseType``.
    /// - parameter exerciseId: the exercise id.
    /// - returns: the parsed ``MKExerciseType`` or ``nil``.
    ///
    static func fromExerciseId(exerciseId: String) -> MKExerciseType? {
        if let (type, rest) = MRExerciseId.componentsFromExerciseId(exerciseId) {
            switch (type, rest) {
            case (resistanceTargeted, let muscleGroup): return MKMuscleGroup.fromId(muscleGroup.first!).map { .ResistanceTargeted(muscleGroups: [$0]) }
            case (resistanceWholeBody, _): return .ResistanceWholeBody
            default: return nil
            }
        }
        return nil
    }
    
    ///
    /// Returns the identity of the type
    ///
    var id: String {
        switch self {
        case .ResistanceTargeted(_): return MKExerciseType.resistanceTargeted
        case .ResistanceWholeBody: return MKExerciseType.resistanceWholeBody
        }
    }
    
//    var prefixes: [String] {
//        switch self {
//        case .Cardio: return ["cardio:"]
//        case .ResistanceTargeted(let muscleGroups): return muscleGroups.map { "\(MKExerciseType.resistanceTargeted)/\($0.prefix)" }
//        case .ResistanceWholeBody: return ["\(MKExerciseType.resistanceTargeted)//" ]
//        }
//    }
//    
//    func containsExerciseId(id: MKExerciseId) -> Bool {
//        for prefix in prefixes {
//            if id.hasPrefix(prefix) { return true }
//        }
//        return false
//    }
    
}
