import Foundation
import MuvrKit

///
/// Provides the exercise id parsing functions
///
extension MKMuscleGroup {
       
    ///
    /// Parses the ``exerciseId`` and returns the muscle groups contained within it
    /// - parameter exerciseId: the exercise id 
    /// - returns: the muscle groups in the exercise id, ``nil`` on missing
    ///
    static func fromExerciseId(exerciseId: String) -> [MKMuscleGroup]? {
        let (_, rest) = MKExercise.componentsFromExerciseId(exerciseId)!
        if rest.count > 1 { return rest.first!.componentsSeparatedByString(",").flatMap { MKMuscleGroup(id: $0) } }
        return nil
    }

}
