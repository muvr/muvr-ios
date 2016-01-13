import Foundation
import MuvrKit

/// Adds property that extracts the MKExerciseType from the Muvr app-specific
/// exercise id
extension MKIncompleteExercise {
    
    /// The exercise type
    var type: MKExerciseType {
        return MKExerciseType(exerciseId: exerciseId)!
    }
        
}
