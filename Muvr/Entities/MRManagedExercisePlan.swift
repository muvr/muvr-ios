import Foundation
import MuvrKit
import CoreData

class MRManagedExercisePlan : NSManagedObject {
 
    var plan: MKExercisePlan<MKExercise.Id> {
        return MKExercisePlan<MKExercise.Id>.fromJsonFirst(planData) { $0 as? String }!
    }
    
}
