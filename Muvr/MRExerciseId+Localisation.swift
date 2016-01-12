import Foundation

extension MRExerciseId {
    
    static func title(exerciseId: String) -> String {
        let (_, e) = MRExerciseId.componentsFromExerciseId(exerciseId)!
        return NSLocalizedString(e.last!, comment: "\(e.last!) exercise").localizedCapitalizedString
    }
    
}
