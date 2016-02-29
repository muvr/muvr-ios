import CoreData
import MuvrKit

///
/// Stores the Markov chain of a user's exercise plans into core data
///
class MRManagedSessionPlan: NSManagedObject {
    
    var plan: MKMarkovPredictor<MKExercisePlan.Id>!
    
}