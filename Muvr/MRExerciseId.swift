import Foundation
import MuvrKit

struct MRExerciseId {

    static func componentsFromExerciseId(exerciseId: MKExerciseId) -> (String, [String])? {
        let components = exerciseId.componentsSeparatedByString(":")
        if components.count == 2 {
            let restComponents = components[1].componentsSeparatedByString("/")
            if restComponents.count == 0 { return nil }
            return (components[0], restComponents)
        }
        return nil
    }
    
}
