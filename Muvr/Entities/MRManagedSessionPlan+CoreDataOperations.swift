import Foundation
import CoreData
import MuvrKit
import CoreLocation

///
/// Provides the CoreData operations
///
extension MRManagedSessionPlan {
    
    ///
    /// Finds session plans whose:
    /// - location, if given, matches within reasonable accuracy
    ///
    /// - parameter location: the location filter
    /// - parameter managedObjectContext: the MOC
    /// - returns: the matching plan
    ///
    static func sessionPlan(atLocation location: MRLocationCoordinate2D?, inManagedObjectContext managedObjectContext: NSManagedObjectContext) -> MRManagedSessionPlan? {
        let fetchRequest = NSFetchRequest(entityName: "MRManagedSessionPlan")
        if let locationPredicate = (location.map { NSPredicate(location: $0) }) {
            fetchRequest.predicate = locationPredicate
        }
        fetchRequest.fetchLimit = 10
        
        let plans = try! managedObjectContext.executeFetchRequest(fetchRequest) as! [MRManagedSessionPlan]
        return plans.first
    }
    
    ///
    /// Upserts ``plan`` for the given ``location`` in the given context.
    ///
    /// - parameter plan: the session plan
    /// - parameter location: the location, if known
    /// - parameter managedObjectContext: the MOC
    /// - returns: the inserted plan
    ///
    static func upsert(plan: MKExercisePlan<MKExerciseType>, location: MRLocationCoordinate2D?, inManagedObjectContext managedObjectContext: NSManagedObjectContext) -> MRManagedSessionPlan {
            if let existing = MRManagedSessionPlan.sessionPlan(atLocation: location, inManagedObjectContext: managedObjectContext) {
                existing.plan = plan
                return existing
            }
            
            let managedPlan = NSEntityDescription.insertNewObjectForEntityForName("MRManagedSessionPlan", inManagedObjectContext: managedObjectContext) as! MRManagedSessionPlan
            managedPlan.longitude = location?.longitude
            managedPlan.latitude = location?.latitude
            managedPlan.plan = plan
            
            return managedPlan
    }
    
}
