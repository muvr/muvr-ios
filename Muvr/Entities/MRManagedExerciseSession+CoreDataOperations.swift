import Foundation
import CoreData
import MuvrKit

extension MRManagedExerciseSession {
    
    static func insert(_ id: String, plan: MRManagedExercisePlan, start: Date, location: MRManagedLocation?, inManagedObjectContext  managedObjectContext: NSManagedObjectContext) -> MRManagedExerciseSession {
        let e = NSEntityDescription.insertNewObject(forEntityName: "MRManagedExerciseSession", into: managedObjectContext) as! MRManagedExerciseSession
        
        e.id = id
        e.plan = plan
        e.start = start
        e.completed = false
        e.uploaded = false
        e.location = location
        
        return e
    }
    
    ///
    /// Fetch the session with the specified id from persistent storage
    ///
    static func fetchSession(withId id: String, inManagedObjectContext managedObjectContext: NSManagedObjectContext) -> MRManagedExerciseSession? {
        let request = NSFetchRequest()
        request.entity = NSEntityDescription.entity(forEntityName: "MRManagedExerciseSession", in: managedObjectContext)
        request.predicate = Predicate(format: "id == %@", id)
        
        let result = try? managedObjectContext.fetch(request) as! [MRManagedExerciseSession]
        return result?.first
    }
    
    
    ///
    /// Check for existing sessions on a given date
    ///
    static func hasSessionsOnDate(_ date: Date, inManagedObjectContext managedObjectContext: NSManagedObjectContext) -> Bool {
        let fetchRequest = NSFetchRequest(entityName: "MRManagedExerciseSession")
        let midnightToday = date.dateOnly
        let midnightTomorrow = midnightToday.addDays(1)
        fetchRequest.predicate = Predicate(format: "(start >= %@ AND start < %@)", midnightToday, midnightTomorrow)
        fetchRequest.fetchLimit = 1
        
        return managedObjectContext.countForFetchRequest(fetchRequest).map { count in count > 0 } ?? false
    }
    
    ///
    /// Fetch the sessions on a given date
    ///
    static func fetchSessionsOnDate(_ date: Date, inManagedObjectContext managedObjectContext: NSManagedObjectContext) -> [MRManagedExerciseSession] {
        let fetchRequest = NSFetchRequest(entityName: "MRManagedExerciseSession")
        let midnightToday = date.dateOnly
        let midnightTomorrow = midnightToday.addDays(1)
        fetchRequest.predicate = Predicate(format: "(start >= %@ AND start < %@)", midnightToday, midnightTomorrow)
        fetchRequest.sortDescriptors = [SortDescriptor(key: "start", ascending: false)]
        
        return (try? managedObjectContext.fetch(fetchRequest) as! [MRManagedExerciseSession]) ?? []
    }
    
    ///
    /// Fetch all the similar sessions since the given date.
    /// A similar sessions is a session based on the same exercise plan as this session.
    /// The sessions must be over (end date is set)
    ///
    /// - parameter date: fetch sessions after this date
    /// - parameter inManagedObjectContext: the MOC to use for the request
    /// - returns a list of all the similar ended session (including this session if ended)
    ///
    func fetchSimilarSessionsSinceDate(_ date: Date, inManagedObjectContext managedObjectContext: NSManagedObjectContext) -> [MRManagedExerciseSession] {
        let fetchRequest = NSFetchRequest(entityName: "MRManagedExerciseSession")
        let from = date.dateOnly
        var predicates = [Predicate(format: "start >= %@", from), Predicate(format: "end != nil")]
        if let templateId = plan.templateId {
            predicates.append(Predicate(format: "plan.templateId = %@", templateId))
        } else {
            predicates.append(Predicate(format: "plan.id = %@", plan.id))
        }
        fetchRequest.predicate = CompoundPredicate(andPredicateWithSubpredicates: predicates)
        fetchRequest.sortDescriptors = [SortDescriptor(key: "start", ascending: false)]
        
        return (try? managedObjectContext.fetch(fetchRequest) as! [MRManagedExerciseSession]) ?? []
    }

}
