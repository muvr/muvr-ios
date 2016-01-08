import Foundation
import MuvrKit

extension MKMuscleGroup {
    
    var title: String {
        return NSLocalizedString("MKMuscleGroup.\(id)", comment: id).localizedCapitalizedString
    }
    
}
