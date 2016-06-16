import Foundation
import MuvrKit

extension MKExerciseTypeDescriptor {
    
    var title: String {
        return NSLocalizedString("MKExerciseType.\(id)", comment: id).localizedCapitalized
    }
    
}
