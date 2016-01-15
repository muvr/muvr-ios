import Foundation
import MuvrKit

extension MKExercise {
    
    var title: String {
        return MRExerciseId.title(id)
    }

}
