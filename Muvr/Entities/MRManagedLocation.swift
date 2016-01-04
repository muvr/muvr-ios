import Foundation
import CoreData
import MuvrKit

class MRManagedLocation: NSManagedObject {

    /// The exercise ids at the given location
    var exerciseIds: [MKExerciseId] {
        return (labels.allObjects as! [MRManagedLocationLabel]).map { $0.exerciseId }
    }

}
