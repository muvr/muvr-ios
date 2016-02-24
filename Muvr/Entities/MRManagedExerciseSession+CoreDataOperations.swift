import Foundation
import CoreData
import MuvrKit

extension MRManagedExerciseSession {
    
    static func insert(id: String, exerciseType: MKExerciseType, start: NSDate, location: MRManagedLocation?, inManagedObjectContext  managedObjectContext: NSManagedObjectContext) -> MRManagedExerciseSession {
        var e = NSEntityDescription.insertNewObjectForEntityForName("MRManagedExerciseSession", inManagedObjectContext: managedObjectContext) as! MRManagedExerciseSession
        
        e.id = id
        e.exerciseType = exerciseType
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
        request.entity = NSEntityDescription.entityForName("MRManagedExerciseSession", inManagedObjectContext: managedObjectContext)
        request.predicate = NSPredicate(format: "id == %@", id)
        
        let result = try? managedObjectContext.executeFetchRequest(request) as! [MRManagedExerciseSession]
        return result?.first
    }
    
    
    ///
    /// Check for existing sessions on a given date
    ///
    static func hasSessionsOnDate(date: NSDate, inManagedObjectContext managedObjectContext: NSManagedObjectContext) -> Bool {
        let fetchRequest = NSFetchRequest(entityName: "MRManagedExerciseSession")
        let midnightToday = date.dateOnly
        let midnightTomorrow = midnightToday.addDays(1)
        fetchRequest.predicate = NSPredicate(format: "(start >= %@ AND start < %@)", midnightToday, midnightTomorrow)
        fetchRequest.fetchLimit = 1
        
        return managedObjectContext.countForFetchRequest(fetchRequest).map { count in count > 0 } ?? false
    }

}
