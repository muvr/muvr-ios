import Foundation
import MuvrKit

extension MKExerciseType {
    
    var title: String {
        return NSLocalizedString("MKExerciseType.\(id)", comment: id).localizedCapitalized
    }
    
}
