import Foundation
import MuvrKit

extension MRManagedFineLocation {
    
    static func exerciseIdsAtMajor(major: NSNumber, minor: NSNumber) -> [MKExercise.Id] {
        if minor.integerValue == 1 {
            return ["resistanceTargeted:arms/dumbbell-biceps-curl"]
        }
        return []
    }
    
}
