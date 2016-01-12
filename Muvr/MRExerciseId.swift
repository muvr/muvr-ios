import Foundation
import MuvrKit

///
/// Provides a single location to extract components for the Muvr app-specific
/// exercise id. 
/// Its structure using pseudo-regex syntax is ``(exercise-type):(muscle-group* /?)(exercise)``
///
struct MRExerciseId {

    ///
    /// Parses the exercise id in Muvr app format to the a tuple containing the type
    /// and a non-empty list of further components. 
    /// - parameter exerciseId: the Muvr formatted exercise id
    /// - returns: (exercise-type, [(muscle-group-1, muscle-group-2, ..., exercise-id)])
    ///
    static func componentsFromExerciseId(exerciseId: MKExerciseId) -> (String, [String])? {
        let components = exerciseId.componentsSeparatedByString(":")
        if components.count == 2 {
            let restComponents = components[1].componentsSeparatedByString("/")
            if restComponents.count == 0 {
                return (components[0], [components[1]])
            }
            return (components[0], restComponents)
        }
        return nil
    }
    
}
