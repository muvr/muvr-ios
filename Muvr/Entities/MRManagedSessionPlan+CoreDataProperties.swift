import Foundation
import CoreData
import MuvrKit

extension MRManagedSessionPlan {
    
    /// the markov chain of exercise plan ids
    @NSManaged private var managedPlan: NSData
    
}

extension MRManagedSessionPlan {
    
    override func awakeFromFetch() {
        plan = MKMarkovPredictor<MKExercisePlan.Id>(json: managedPlan) { $0 as? MKExercisePlan.Id }
    }
    
    override func awakeFromInsert() {
        plan = MKMarkovPredictor<MKExercisePlan.Id>()
    }
    
    func insert(exercisePlanId: MKExercisePlan.Id) {
        plan.insert(exercisePlanId)
        managedPlan = plan.json { $0 }
    }
    
    var next: [MKExercisePlan.Id] {
        return plan.next
    }
    
}