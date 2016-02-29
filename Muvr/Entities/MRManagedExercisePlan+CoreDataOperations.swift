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
    /// - plan is not created from a template (adhoc session)
    ///
    /// - parameter exerciseType: the exercise type filter
    /// - parameter location: the location filter
    /// - parameter managedObjectContext: the MOC
    /// - returns: the matching plan
    ///
    static func exactPlanForExerciseType(exerciseType: MKExerciseType, location: MRLocationCoordinate2D?, inManagedObjectContext managedObjectContext: NSManagedObjectContext) -> MRManagedExercisePlan? {
        let fetchRequest = NSFetchRequest(entityName: "MRManagedExercisePlan")
        var predicate = NSPredicate(exerciseType: exerciseType)
        let adHocSessionPredicate = NSPredicate(format: "templateId = nil")
        if let locationPredicate = (location.map { NSPredicate(location: $0) }) {
            predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate, locationPredicate, adHocSessionPredicate])
        }
        fetchRequest.predicate = predicate
        fetchRequest.fetchLimit = 1
        
        let plans = try! managedObjectContext.executeFetchRequest(fetchRequest) as! [MRManagedExercisePlan]
        return plans.first
    }
    
    ///
    /// Finds exercise plans whose:
    /// - location, if given, matches within reasonable accuracy
    /// - id matches the given ``id`` precisely,
    ///
    /// - parameter id: the id filter
    /// - parameter location: the location filter
    /// - parameter managedObjectContext: the MOC
    /// - returns: the matching plan
    ///
    static func exactPlanForId(id: String, location: MRLocationCoordinate2D?, inManagedObjectContext managedObjectContext: NSManagedObjectContext) -> MRManagedExercisePlan? {
        let fetchRequest = NSFetchRequest(entityName: "MRManagedExercisePlan")
        var predicate = NSPredicate(format: "id = %@", id)
        if let locationPredicate = (location.map { NSPredicate(location: $0) }) {
            predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate, locationPredicate])
        }
        fetchRequest.predicate = predicate
        fetchRequest.fetchLimit = 1
        
        let plans = try! managedObjectContext.executeFetchRequest(fetchRequest) as! [MRManagedExercisePlan]
        
        return plans.first
    }
    
    ///
    /// Finds exercise plans whose:
    /// - location, if given, matches within reasonable accuracy; falling back on any location
    /// - id, if given, matches the given ``id`` precisely; falling back on more general plans.
    /// - exercise type matches the given ``type`` precisely; falling back on more general plans.
    ///
    /// More general plans here mean plans that list only some of the muscle groups specified in case
    /// of targeted resistance exercise.
    ///
    /// - parameter exerciseType: the exercise type filter
    /// - parameter id: the plan id
    /// - parameter location: the location filter
    /// - parameter managedObjectContext: the MOC
    /// - returns: the matching plan
    ///
    static func planForExerciseType(exerciseType: MKExerciseType, id: String?, location: MRLocationCoordinate2D?, inManagedObjectContext managedObjectContext: NSManagedObjectContext) -> MRManagedExercisePlan? {
        if let id = id {
            // first, try exact match by id and location
            if let found = exactPlanForId(id, location: location, inManagedObjectContext: managedObjectContext) { return found }
            // next try by id without location
            if location != nil, let found = exactPlanForId(id, location: location, inManagedObjectContext: managedObjectContext) { return found }
        }
        // next, try exact match by exercise type and location
        if let found = exactPlanForExerciseType(exerciseType, location: location, inManagedObjectContext: managedObjectContext) { return found }
        // next, try without location, but only if we had not tried already
        if location != nil, let found = exactPlanForExerciseType(exerciseType, location: nil, inManagedObjectContext: managedObjectContext) { return found }
        // no match
        return nil
    }
    
    ///
    /// Insert a new ``plan`` for the given ``exerciseType`` and ``location`` in the given context.
    ///
    /// - parameter exerciseType: the exercise type
    /// - parameter location: the location, if known
    /// - parameter managedObjectContext: the MOC
    /// - returns: the inserted plan
    ///
    static func insertNewObject(exerciseType: MKExerciseType, location: MRLocationCoordinate2D?,
        inManagedObjectContext managedObjectContext: NSManagedObjectContext) -> MRManagedExercisePlan {
        
            var managedPlan = NSEntityDescription.insertNewObjectForEntityForName("MRManagedExercisePlan", inManagedObjectContext: managedObjectContext) as! MRManagedExercisePlan
            managedPlan.longitude = location?.longitude
            managedPlan.latitude = location?.latitude
            managedPlan.exerciseType = exerciseType
            managedPlan.id = NSUUID().UUIDString
        
            return managedPlan
    }
    
}
