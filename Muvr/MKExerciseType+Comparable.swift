import Foundation
import MuvrKit

extension MKExerciseType : Comparable {
    
}

public func <(lhs: MKExerciseType, rhs: MKExerciseType) -> Bool {
    switch (lhs, rhs) {
    case (.ResistanceTargeted(let lmgs), .ResistanceTargeted(let rmgs)) where lmgs.count == 1 && rmgs.count == 1:
        return lmgs.first!.title < rmgs.first!.title
    default: return lhs.id < rhs.id
    }
}