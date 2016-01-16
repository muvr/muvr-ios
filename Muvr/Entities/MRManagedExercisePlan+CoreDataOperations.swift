import Foundation
import CoreData
import MuvrKit
import CoreLocation

///
/// Provides the CoreData operations
///
extension MRManagedExercisePlan {
    
    ///
    /// Finds exercise plans whose:
    /// - location, if given, matches within reasonable accuracy
    /// - exercise type matches the given ``type`` precisely,
    ///
    /// - parameter exerciseType: the exercise type filter
    /// - parameter location: the location filter
    /// - parameter managedObjectContext: the MOC
    /// - returns: the matching plan
    ///
    static func exactPlanForExerciseType(exerciseType: MKExerciseType, location: MRLocationCoordinate2D?, inManagedObjectContext managedObjectContext: NSManagedObjectContext) -> MRManagedExercisePlan? {
        let fetchRequest = NSFetchRequest(entityName: "MRManagedExercisePlan")
        var predicate = NSPredicate(exerciseType: exerciseType)
        if let locationPredicate = (location.map { NSPredicate(location: $0) }) {
            predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate, locationPredicate])
        }
        fetchRequest.predicate = predicate
        fetchRequest.fetchLimit = 10
        
        let plans = try! managedObjectContext.executeFetchRequest(fetchRequest) as! [MRManagedExercisePlan]
        return plans.first
    }
    
    ///
    /// Finds exercise plans whose:
    /// - location, if given, matches within reasonable accuracy; falling back on any location
    /// - exercise type matches the given ``type`` precisely; falling back on more general plans.
    ///
    /// More general plans here mean plans that list only some of the muscle groups specified in case
    /// of targeted resistance exercise.
    ///
    /// - parameter exerciseType: the exercise type filter
    /// - parameter location: the location filter
    /// - parameter managedObjectContext: the MOC
    /// - returns: the matching plan
    ///
    static func planForExerciseType(exerciseType: MKExerciseType, location: MRLocationCoordinate2D?, inManagedObjectContext managedObjectContext: NSManagedObjectContext) -> MRManagedExercisePlan? {
        // first, try exact match
        if let found = exactPlanForExerciseType(exerciseType, location: location, inManagedObjectContext: managedObjectContext) {
            return found
        }
        // next, try without location, but only if we had not tried already
        if location != nil {
            if let found = exactPlanForExerciseType(exerciseType, location: nil, inManagedObjectContext: managedObjectContext) {
                return found
            }
        }
        // no match
        return nil
    }
    
    ///
    /// Upserts ``plan`` for the given ``exerciseType`` and ``location`` in the given context.
    ///
    /// - parameter plan: the exercise plan
    /// - parameter exerciseType: the exercise type
    /// - parameter location: the location, if known
    /// - parameter managedObjectContext: the MOC
    /// - returns: the inserted plan
    ///
    static func upsertPlan(plan: MKExercisePlan<MKExercise.Id>, exerciseType: MKExerciseType, location: MRLocationCoordinate2D?,
        inManagedObjectContext managedObjectContext: NSManagedObjectContext) -> MRManagedExercisePlan {
            
            if let existing = MRManagedExercisePlan.exactPlanForExerciseType(exerciseType, location: location, inManagedObjectContext: managedObjectContext) {
                existing.plan = plan
                return existing
            }
            
            var managedPlan = NSEntityDescription.insertNewObjectForEntityForName("MRManagedExercisePlan", inManagedObjectContext: managedObjectContext) as! MRManagedExercisePlan
            managedPlan.longitude = location?.longitude
            managedPlan.latitude = location?.latitude
            managedPlan.plan = plan
            managedPlan.exerciseType = exerciseType
            
            return managedPlan
    }
    
}
