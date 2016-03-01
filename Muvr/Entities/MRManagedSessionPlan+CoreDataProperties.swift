import Foundation
import CoreData
import MuvrKit

extension MRManagedSessionPlan {
    
    /// the markov chain of exercise plan ids
    @NSManaged private var managedPlan: NSData?
    
}

extension MRManagedSessionPlan {
    
    override func awakeFromFetch() {
        if let data = managedPlan {
            plan = MKMarkovPredictor<MKExercisePlan.Id>(json: data) { $0 as? MKExercisePlan.Id }
        } else {
            plan = MKMarkovPredictor<MKExercisePlan.Id>()
            managedPlan = plan.json { $0 }
        }
    }
    
    override func awakeFromInsert() {
        plan = MKMarkovPredictor<MKExercisePlan.Id>()
        managedPlan = plan.json { $0 }
    }
    
    func insert(exercisePlanId: MKExercisePlan.Id) {
        plan.insert(exercisePlanId)
        managedPlan = plan.json { $0 }
    }
    
    var next: [MKExercisePlan.Id] {
        return plan.next
    }
    
}