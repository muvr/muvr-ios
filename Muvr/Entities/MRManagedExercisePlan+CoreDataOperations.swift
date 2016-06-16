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
    internal static func exactPlanForExerciseType(_ exerciseType: MKExerciseType, location: MRLocationCoordinate2D?, inManagedObjectContext managedObjectContext: NSManagedObjectContext) -> MRManagedExercisePlan? {
        let fetchRequest = NSFetchRequest<MRManagedExercisePlan>(entityName: "MRManagedExercisePlan")
        var predicate = Predicate(exerciseType: exerciseType)
        let adHocSessionPredicate = Predicate(format: "templateId = nil")
        if let locationPredicate = (location.map { Predicate(location: $0) }) {
            predicate = CompoundPredicate(andPredicateWithSubpredicates: [predicate, locationPredicate, adHocSessionPredicate])
        }
        fetchRequest.predicate = predicate
        fetchRequest.fetchLimit = 1
        
        let plans = try! managedObjectContext.fetch(fetchRequest)
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
    internal static func exactPlanForId(_ id: String, location: MRLocationCoordinate2D?, inManagedObjectContext managedObjectContext: NSManagedObjectContext) -> MRManagedExercisePlan? {
        let fetchRequest = NSFetchRequest(entityName: "MRManagedExercisePlan")
        var predicate = Predicate(format: "id = %@", id)
        if let locationPredicate = (location.map { Predicate(location: $0) }) {
            predicate = CompoundPredicate(andPredicateWithSubpredicates: [predicate, locationPredicate])
        }
        fetchRequest.predicate = predicate
        fetchRequest.fetchLimit = 1
        
        let plans = try! managedObjectContext.fetch(fetchRequest) as! [MRManagedExercisePlan]
        
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
    internal static func exactPlanForTemplateId(_ templateId: String, location: MRLocationCoordinate2D?, inManagedObjectContext managedObjectContext: NSManagedObjectContext) -> MRManagedExercisePlan? {
        let fetchRequest = NSFetchRequest(entityName: "MRManagedExercisePlan")
        var predicate = Predicate(format: "templateId = %@", templateId)
        if let locationPredicate = (location.map { Predicate(location: $0) }) {
            predicate = CompoundPredicate(andPredicateWithSubpredicates: [predicate, locationPredicate])
        }
        fetchRequest.predicate = predicate
        fetchRequest.fetchLimit = 1
        
        let plans = try! managedObjectContext.fetch(fetchRequest) as! [MRManagedExercisePlan]
        
        return plans.first
    }
    
    ///
    /// Finds exercise plans whose:
    /// - location, if given, matches within reasonable accuracy; falling back on any location
    /// - id, if given, matches the given ``id`` precisely
    ///
    /// - parameter id: the plan id
    /// - parameter location: the location filter
    /// - parameter managedObjectContext: the MOC
    /// - returns: the matching plan
    ///
    static func planForId(_ id: String, location: MRLocationCoordinate2D?, inManagedObjectContext managedObjectContext: NSManagedObjectContext) -> MRManagedExercisePlan? {
        // try to find plan matching id and location
        if let found = MRManagedExercisePlan.exactPlanForId(id, location: location, inManagedObjectContext: managedObjectContext) { return found }
        // next try any location
        if let found = MRManagedExercisePlan.exactPlanForId(id, location: nil, inManagedObjectContext: managedObjectContext) { return found }
        // not found
        return nil
    }
    
    ///
    /// Finds or create exercise plans whose:
    /// - location, if given, matches within reasonable accuracy; falling back on any location
    /// - id, if given, matches the given ``id`` precisely; falling back on more general plans.
    /// - exercise type matches the given ``type`` precisely; falling back on more general plans.
    ///
    /// If no matching plan is found at the current location, a new plan is created.
    ///
    /// - parameter sessionType: the session type filter
    /// - parameter id: the plan id
    /// - parameter location: the location filter
    /// - parameter managedObjectContext: the MOC
    /// - returns: the matching plan
    ///
    static func planForSessionType(_ sessionType: MRSessionType, location: MRLocationCoordinate2D?, inManagedObjectContext managedObjectContext: NSManagedObjectContext) -> MRManagedExercisePlan {
        switch sessionType {
        case .userDefined(let p):
            if let found = exactPlanForId(p.id, location: location, inManagedObjectContext: managedObjectContext) { return found }
            if let found = exactPlanForId(p.id, location: nil, inManagedObjectContext: managedObjectContext) {
                if let location = location {
                    return MRManagedExercisePlan.copyAtLocation(found, location: location, inManagedObjectContext: managedObjectContext)
                }
                return found
            }
            return MRManagedExercisePlan.insertNewObject(sessionType, location: location, inManagedObjectContext: managedObjectContext)
        case .Predefined(let p):
            if let found = exactPlanForTemplateId(p.id, location: location, inManagedObjectContext: managedObjectContext) { return found }
            if let found = exactPlanForTemplateId(p.id, location: nil, inManagedObjectContext: managedObjectContext) {
                if let location = location {
                    return MRManagedExercisePlan.copyAtLocation(found, location: location, inManagedObjectContext: managedObjectContext)
                }
                return found
            }
            return MRManagedExercisePlan.insertNewObject(sessionType, location: location, inManagedObjectContext: managedObjectContext)
        case .AdHoc(let exerciseType):
            if let found = exactPlanForExerciseType(exerciseType, location: location, inManagedObjectContext: managedObjectContext) { return found }
            if let found = exactPlanForExerciseType(exerciseType, location: nil, inManagedObjectContext: managedObjectContext) {
                if let location = location {
                    return MRManagedExercisePlan.copyAtLocation(found, location: location, inManagedObjectContext: managedObjectContext)
                }
                return found
            }
            return MRManagedExercisePlan.insertNewObject(sessionType, location: location, inManagedObjectContext: managedObjectContext)
        }
    }
    
    ///
    /// Create a copy of a ``plan`` at ``location`` in the given context.
    ///
    /// - parameter exercisePlan: the exercise plan to copy
    /// - parameter location: the location, if known
    /// - parameter managedObjectContext: the MOC
    /// - returns: the inserted plan
    ///
    internal static func copyAtLocation(_ exercisePlan: MRManagedExercisePlan, location: MRLocationCoordinate2D?, inManagedObjectContext managedObjectContext: NSManagedObjectContext) -> MRManagedExercisePlan {
        
        if exercisePlan.longitude != location?.longitude && exercisePlan.latitude != location?.latitude {
            return MRManagedExercisePlan.insertNewObject(.userDefined(plan: exercisePlan), location: location, inManagedObjectContext: managedObjectContext)
        }
        return exercisePlan
    }
    
    ///
    /// Insert a new ``managed plan`` for the given ``plan`` and ``location`` in the given context.
    ///
    /// - parameter exerciseType: the exercise type
    /// - parameter location: the location, if known
    /// - parameter managedObjectContext: the MOC
    /// - returns: the inserted plan
    ///
    internal static func insertNewObject(_ sessionType: MRSessionType, location: MRLocationCoordinate2D?,
        inManagedObjectContext managedObjectContext: NSManagedObjectContext) -> MRManagedExercisePlan {
        
        var managedPlan = NSEntityDescription.insertNewObject(forEntityName: "MRManagedExercisePlan", into: managedObjectContext) as! MRManagedExercisePlan
        managedPlan.longitude = location?.longitude
        managedPlan.latitude = location?.latitude
        managedPlan.id = UUID().uuidString
        managedPlan.name = sessionType.name
        
        switch sessionType {
        case .AdHoc(let exerciseType):
            managedPlan.exerciseType = exerciseType
        case .Predefined(let p):
            managedPlan.exerciseType = p.exerciseType
            managedPlan.templateId = p.id
            managedPlan.setPlan(p.plan)
        case .userDefined(let mp):
            managedPlan.exerciseType = mp.exerciseType
            managedPlan.templateId = mp.templateId
            managedPlan.id = mp.id
            managedPlan.setPlan(mp.plan)
        }
        
        return managedPlan
    }
    
    ///
    /// set the `plan` property by making a copy of the given plan
    /// - parameter plan the plan to set
    ///
    private func setPlan(_ plan: MKMarkovPredictor<MKExercisePlan.Id>) {
        let json = plan.json { $0 }
        self.plan = MKMarkovPredictor<MKExercisePlan.Id>(json: json) { $0 as? MKExercisePlan.Id }
    }
    
}
