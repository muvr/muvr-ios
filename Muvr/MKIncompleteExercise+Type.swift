import Foundation
import MuvrKit

extension MKIncompleteExercise {
    
    var type: MKExerciseType {
        let components = exerciseId.componentsSeparatedByString("/")
        assert(components.count >= 3)
        return MKExerciseType.fromExerciseId(exerciseId)!
    }
        
}
