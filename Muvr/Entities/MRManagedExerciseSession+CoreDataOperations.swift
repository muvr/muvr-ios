import Foundation
import MuvrKit
import CoreData

///
/// Adds CoreData related operations: inserts, selects, ...
///
extension MRManagedExerciseSession {
    
    ///
    /// Finds all uploadable sessions in the given context. It is expected that the returned
    /// sessions will be each uploaded, its ``uploaded`` property set to ``true`` and then
    /// saved in the same ``managedObjectContext``.
    ///
    /// - parameter managedObjectContext: the MOC
    /// - returns: array of MRManagedExerciseSession that have not yet been uploaded
    ///
    static func findUploadableSessions(inManagedObjectContext managedObjectContext: NSManagedObjectContext) -> [MRManagedExerciseSession] {
        let fetchRequest = NSFetchRequest(entityName: "MRManagedExerciseSession")
        fetchRequest.predicate = NSPredicate(format: "(uploaded == false && completed = true)")
        
        return try! managedObjectContext.executeFetchRequest(fetchRequest) as! [MRManagedExerciseSession]
    }

    ///
    /// Returns an array of sessions on the given date, ordered by start date
    /// - parameter date: the day the sessions should have started in
    /// - parameter managedObjectContext: the MOC
    /// - returns: the sessions ordered by their start time
    ///
    static func sessionsOnDate(date: NSDate, inManagedObjectContext managedObjectContext: NSManagedObjectContext) -> [MRManagedExerciseSession] {
        let fetchRequest = NSFetchRequest(entityName: "MRManagedExerciseSession")
        let midnightToday = date.dateOnly
        let midnightTomorrow = midnightToday.addDays(1)
        fetchRequest.predicate = NSPredicate(format: "(start >= %@ AND start < %@)", midnightToday, midnightTomorrow)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "start", ascending: false)]
        
        return try! managedObjectContext.executeFetchRequest(fetchRequest) as! [MRManagedExerciseSession]
    }
    
    ///
    /// Returns a session identified by ``sessionId``; this is _not_ the ``objectID``.
    /// - parameter sessionId: the session identity
    /// - parameter managedObjectContext: the MOC
    /// - returns: the session
    ///
    static func sessionById(sessionId: String, inManagedObjectContext managedObjectContext: NSManagedObjectContext) -> MRManagedExerciseSession? {
        let fetchRequest = NSFetchRequest(entityName: "MRManagedExerciseSession")
        fetchRequest.predicate = NSPredicate(format: "(id == %@)", sessionId)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "start", ascending: false)]
        fetchRequest.fetchLimit = 1
        
        let result = try! managedObjectContext.executeFetchRequest(fetchRequest) as! [MRManagedExerciseSession]
        return result.first
    }
    
    ///
    /// Indicates whether there are sessions that started on the given ``date``;
    /// - parameter date: the date
    /// - parameter managedObjectContext: the MOC
    /// - returns: true if there is at least one session that started on the day represented by ``date``
    ///
    static func hasSessionsOnDate(date: NSDate, inManagedObjectContext managedObjectContext: NSManagedObjectContext) -> Bool {
        let fetchRequest = NSFetchRequest(entityName: "MRManagedExerciseSession")
        let midnightToday = date.dateOnly
        let midnightTomorrow = midnightToday.addDays(1)
        fetchRequest.predicate = NSPredicate(format: "(start >= %@ AND start < %@)", midnightToday, midnightTomorrow)
        fetchRequest.fetchLimit = 1
        
        return managedObjectContext.countForFetchRequest(fetchRequest).map { $0 > 0 } ?? false
        
    }

    ///
    /// Creates a new ``Self`` in the ``managedObjectContext``. All its properties will be unset after this call.
    /// - parameter managedObjectContext: the MOC
    /// - returns: Self with all properties unset
    ///
    static func insertNewObject(inManagedObjectContext managedObjectContext: NSManagedObjectContext) -> MRManagedExerciseSession {
        let mo = NSEntityDescription.insertNewObjectForEntityForName("MRManagedExerciseSession", inManagedObjectContext: managedObjectContext) as! MRManagedExerciseSession
        
        return mo
    }
    
    ///
    /// Creates a new ``Self`` in the ``managedObjectContext`` with its properties set from ``session``.
    /// - parameter session: the session to base the properties of ``Self`` on
    /// - parameter managedObjectContext: the MOC
    /// - returns: Self with all properties unset
    ///
    static func insertNewObject(from session: MKExerciseSession, inManagedObjectContext managedObjectContext: NSManagedObjectContext) -> MRManagedExerciseSession {
        let mo = insertNewObject(inManagedObjectContext: managedObjectContext)
        mo.id = session.id
        mo.start = session.start
        mo.exerciseModelId = session.exerciseModelId
        mo.completed = session.completed
        mo.uploaded = false
        
        return mo
    }

}
