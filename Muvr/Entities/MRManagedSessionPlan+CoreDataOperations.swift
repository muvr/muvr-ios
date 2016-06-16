import Foundation
import CoreData
import MuvrKit
import CoreLocation

///
/// Provides the CoreData operations
///
extension MRManagedSessionPlan {

    ///
    /// Loads the user's session plan
    /// - parameter managedObjectContext: the MOC
    /// - returns: the user session plan or nil if not found
    ///
    static func find(inManagedObjectContext managedObjectContext: NSManagedObjectContext) -> MRManagedSessionPlan? {
        let fetchRequest = NSFetchRequest<MRManagedSessionPlan>(entityName: "MRManagedSessionPlan")
        fetchRequest.fetchLimit = 1
        
        let plans = try! managedObjectContext.fetch(fetchRequest)
        if let p = plans.first where p.plan == nil { p.awakeFromFetch() }
        return plans.first
    }
    
    ///
    /// Insert a new session plan.
    ///
    /// - parameter managedObjectContext: the MOC
    /// - returns: the inserted plan
    ///
    static func insertNewObject(_ plan: MKMarkovPredictor<MKExercisePlan.Id>, inManagedObjectContext managedObjectContext: NSManagedObjectContext) -> MRManagedSessionPlan {
        return NSEntityDescription.insertNewObject(forEntityName: "MRManagedSessionPlan", into: managedObjectContext) as! MRManagedSessionPlan
    }
    
}
