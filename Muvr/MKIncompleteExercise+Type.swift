import Foundation
import MuvrKit

extension MKIncompleteExercise {
    
    var type: MKExerciseType {
        return MKExerciseType.fromExerciseId(exerciseId)!
    }
        
}
