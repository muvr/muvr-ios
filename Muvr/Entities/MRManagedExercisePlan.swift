import Foundation
import MuvrKit
import CoreData

class MRManagedExercisePlan : NSManagedObject {
 
    var plan: MKExercisePlan<MKExerciseId> {
        return MKExercisePlan<MKExerciseId>.fromJsonFirst(planData) { $0 as? String }!
    }
    
}
