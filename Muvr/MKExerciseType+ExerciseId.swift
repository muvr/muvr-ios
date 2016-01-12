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
    
}
