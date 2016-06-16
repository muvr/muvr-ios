import Foundation
import CoreData
import MuvrKit

///
/// The session plan properties stored into core data
///
extension MRManagedSessionPlan {
    
    /// the markov chain of exercise plan ids
    @NSManaged private var managedPlan: Data?
    
}

///
/// Provides easier access to the exercise plans Markov predictor
/// - ``insert`` and ``next`` can be called directly on ``MRManagedSessionPlan`` instance
/// - automatically (de)serialize the markov chain from/to JSON
///
extension MRManagedSessionPlan {
    
    ///
    /// Called by core data when instance is fetched.
    /// Unserialize and setup the MKMarkovPredictor from the stored JSON data
    ///
    override func awakeFromFetch() {
        if let data = managedPlan {
            plan = MKMarkovPredictor<MKExercisePlan.Id>(json: data) { $0 as? MKExercisePlan.Id }
        } else {
            plan = MKMarkovPredictor<MKExercisePlan.Id>()
            managedPlan = plan.json { $0 }
        }
    }
    
    ///
    /// Called by core data when instance is inserted.
    /// Setup an empty MKMarkovPredictor for the exercise plan list
    ///
    override func awakeFromInsert() {
        plan = MKMarkovPredictor<MKExercisePlan.Id>()
        managedPlan = plan.json { $0 }
    }
    
    ///
    /// Insert a new exercise plan id into the chain.
    ///
    /// It automatically updates the serialised JSON data
    /// (just save the associated ``NSManagedObjectContext`` to persist the data)
    ///
    func insert(_ exercisePlanId: MKExercisePlan.Id) {
        plan.insert(exercisePlanId)
        managedPlan = plan.json { $0 }
    }
    
    ///
    /// The list (most likely first) of upcoming exercise plan ids
    ///
    var next: [MKExercisePlan.Id] {
        return plan.next
    }
    
}
