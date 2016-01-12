import Foundation

///
/// Adds JSON serialization to MKExerciseType
///
extension MKExerciseType {
    
    ///
    /// JSON representation of this instance
    ///
    public var json: MKExerciseTypeJson {
        switch self {
        case .ResistanceWholeBody: return ["type": "resistanceWholeBody"]
        case .ResistanceTargeted(let muscleGroups): return ["type":"resistanceTargeted", "muscleGroups": muscleGroups.map { $0.json }]
        }
    }
    
    ///
    /// Load an instance of this type from the JSON ``data``
    /// - parameter data: the NSData representing valid JSON
    /// - returns: the MKExerciseType
    ///
    public static func fromJson(data: MKExerciseTypeJson?) -> MKExerciseType? {
        guard let data = data else { return nil}
        guard let type = data["type"] as? String else { return nil }
        switch type {
        case "resistanceWholeBody":
            return .ResistanceWholeBody
        case "resistanceTargeted":
            guard let muscleGroups = data["muscleGroups"] as? [MKMuscleGroupJson] else { return nil }
            return .ResistanceTargeted(muscleGroups: muscleGroups.flatMap(MKMuscleGroup.fromJson))
        default: return nil
        }
    }
}

///
/// The exercise type json
///
public typealias MKExerciseTypeJson = [String: AnyObject]
