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
    /// - location, if given, matches within reasonable accuracy
    /// - templateId matches the given ``templateId`` precisely,
    ///
    /// - parameter templateId: the template id filter
    /// - parameter location: the location filter
    /// - parameter managedObjectContext: the MOC
    /// - returns: the matching plan
    ///
    static func exactPlanForTemplateId(templateId: String, location: MRLocationCoordinate2D?, inManagedObjectContext managedObjectContext: NSManagedObjectContext) -> MRManagedExercisePlan? {
        let fetchRequest = NSFetchRequest(entityName: "MRManagedExercisePlan")
        var predicate = NSPredicate(format: "templateId = %@", templateId)
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
    static func planFor(exercisePlan: MRExercisePlan, location: MRLocationCoordinate2D?, inManagedObjectContext managedObjectContext: NSManagedObjectContext) -> MRManagedExercisePlan? {
        switch exercisePlan {
        case .UserDef(let p):
            if let found = exactPlanForId(p.id, location: location, inManagedObjectContext: managedObjectContext) { return found }
            if let found = exactPlanForId(p.id, location: nil, inManagedObjectContext: managedObjectContext) {
                if let location = location {
                    return MRManagedExercisePlan.copyAtLocation(found, location: location, inManagedObjectContext: managedObjectContext)
                }
                return found
            }
        case .Predef(let p):
            if let found = exactPlanForTemplateId(p.id, location: location, inManagedObjectContext: managedObjectContext) { return found }
            if let found = exactPlanForTemplateId(p.id, location: nil, inManagedObjectContext: managedObjectContext) {
                if let location = location {
                    return MRManagedExercisePlan.copyAtLocation(found, location: location, inManagedObjectContext: managedObjectContext)
                }
                return found
            }
            return MRManagedExercisePlan.insertNewObject(exercisePlan, location: location, inManagedObjectContext: managedObjectContext)
        case .AdHoc(let p):
            if let found = exactPlanForExerciseType(p.exerciseType, location: location, inManagedObjectContext: managedObjectContext) { return found }
            if let found = exactPlanForExerciseType(p.exerciseType, location: nil, inManagedObjectContext: managedObjectContext) {
                if let location = location {
                    return MRManagedExercisePlan.copyAtLocation(found, location: location, inManagedObjectContext: managedObjectContext)
                }
                return found
            }
            return MRManagedExercisePlan.insertNewObject(exercisePlan, location: location, inManagedObjectContext: managedObjectContext)
        }
        // no match
        return nil
    }
    
    ///
    /// Create a copy of a ``plan`` at ``location`` in the given context.
    ///
    /// - parameter exercisePlan: the exercise plan to copy
    /// - parameter location: the location, if known
    /// - parameter managedObjectContext: the MOC
    /// - returns: the inserted plan
    ///
    static func copyAtLocation(exercisePlan: MRManagedExercisePlan, location: MRLocationCoordinate2D?, inManagedObjectContext managedObjectContext: NSManagedObjectContext) -> MRManagedExercisePlan {
        
        var managedPlan = NSEntityDescription.insertNewObjectForEntityForName("MRManagedExercisePlan", inManagedObjectContext: managedObjectContext) as! MRManagedExercisePlan
        managedPlan.longitude = location?.longitude
        managedPlan.latitude = location?.latitude
        managedPlan.exerciseType = exercisePlan.exerciseType
        managedPlan.name = exercisePlan.name
        managedPlan.templateId = exercisePlan.templateId
        managedPlan.id = exercisePlan.id
        managedPlan.plan = exercisePlan.plan
        
        return managedPlan
    }
    
    ///
    /// Insert a new ``plan`` for the given ``template`` and ``location`` in the given context.
    ///
    /// - parameter exerciseType: the exercise type
    /// - parameter location: the location, if known
    /// - parameter managedObjectContext: the MOC
    /// - returns: the inserted plan
    ///
    static func insertNewObject(template: MRExercisePlan, location: MRLocationCoordinate2D?,
        inManagedObjectContext managedObjectContext: NSManagedObjectContext) -> MRManagedExercisePlan {
        
            var managedPlan = NSEntityDescription.insertNewObjectForEntityForName("MRManagedExercisePlan", inManagedObjectContext: managedObjectContext) as! MRManagedExercisePlan
            managedPlan.longitude = location?.longitude
            managedPlan.latitude = location?.latitude
            managedPlan.exerciseType = template.exercisePlan.exerciseType
            if case .Predef(let p) = template {
                managedPlan.templateId = p.id
                managedPlan.plan = p.plan
            }
            managedPlan.id = NSUUID().UUIDString
        
            return managedPlan
    }
    
    
    
}
