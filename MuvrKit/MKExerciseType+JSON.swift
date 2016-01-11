import Foundation

///
/// Adds JSON serialization to MKExerciseType
///
extension MKExerciseType {
    
    ///
    /// JSON representation of this instance
    ///
    public var json: NSData {
        switch self {
        case .ResistanceWholeBody:
            return try! NSJSONSerialization.dataWithJSONObject(["type":"resistanceWholeBody"], options: [])
        case .ResistanceTargeted(let muscleGroups):
            return try! NSJSONSerialization.dataWithJSONObject(["type":"resistanceTargeted", "muscleGroups":muscleGroups.map { $0.json }], options: [])
        }
    }
    
    ///
    /// Load an instance of this type from the JSON ``data``
    /// - parameter data: the NSData representing valid JSON
    /// - returns: the MKExerciseType
    ///
    public static func fromJson(data: NSData) -> MKExerciseType? {
        if let json = try? NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments),
            let dict = json as? [String : AnyObject],
            let type = json["type"] as? String {
            switch type {
            case "resistanceWholeBody":
                return .ResistanceWholeBody
            case "resistanceTargeted":
                if let muscleGroups = dict["muscleGroups"] as? [AnyObject] {
                    return .ResistanceTargeted(muscleGroups: muscleGroups.flatMap(MKMuscleGroup.fromJson))
                }
            default: return nil
            }
        }
        
        return nil
    }
    
}
