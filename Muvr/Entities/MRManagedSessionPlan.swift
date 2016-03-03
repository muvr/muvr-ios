import CoreData
import MuvrKit

///
/// Contains the user's exercise plan ids
/// (The exercise plans id are stored in a MarkovChain)
///
class MRManagedSessionPlan: NSManagedObject {

    internal var plan: MKMarkovPredictor<MKExercisePlan.Id>!
    
}