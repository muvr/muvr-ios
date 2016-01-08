import Foundation
import MuvrKit

extension MKIncompleteExercise {
    
    var title: String {
        return MRExerciseId.title(exerciseId)
    }

}
