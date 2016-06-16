import Foundation
import MuvrKit

///
/// Provides a single location to extract components for the Muvr app-specific
/// exercise id. 
/// Its structure using pseudo-regex syntax is ``(exercise-type):(muscle-group* /?)(exercise)``
///
extension MKExercise {
    
    /// The exercise type
    var type: MKExerciseType {
        if let type = MKExerciseType(exerciseId: id) {
            return type
        }
        fatalError("Cannot get type for \(id)")
    }

    ///
    /// Computes a title for the given exercise id
    ///
    static func title(_ exerciseId: Id) -> String {
        let (_, e, _) = componentsFromExerciseId(exerciseId)!
        return NSLocalizedString(e.last!, comment: "\(e.last!) exercise").localizedCapitalizedString
    }

    ///
    /// Parses the exercise id in Muvr app format to the a tuple containing the type
    /// and a non-empty list of further components. 
    /// - parameter exerciseId: the Muvr formatted exercise id
    /// - returns: (exercise-type, [(muscle-group-1, muscle-group-2, ...], exercise-id, station?))
    ///
    static func componentsFromExerciseId(_ exerciseId: MKExercise.Id) -> (String, [String], String?)? {
        let components = exerciseId.componentsSeparatedByString(":")
        if components.count == 2 {
            let restComponents = components[1].componentsSeparatedByString("/")
            if restComponents.count == 0 {
                return (components[0], [components[1]], nil)
            }
            // restComponents is NEL
            let nas = restComponents.last!.componentsSeparatedByString("@")
            if nas.count == 2 {
                // the last component is station
                return (components[0], restComponents.dropLast() + [nas.first!], nas.last!)
            }
            // the last component is not a station
            return (components[0], restComponents, nil)
        }
        return (exerciseId, [], nil)
    }
    
}
