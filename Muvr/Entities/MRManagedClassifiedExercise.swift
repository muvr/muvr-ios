import Foundation
import CoreData
import MuvrKit

class MRManagedClassifiedExercise: NSManagedObject {
    
    func isBefore(other: MRManagedClassifiedExercise) -> Bool {
        return start.compare(other.start) == .OrderedAscending
    }

}
