import Foundation
import MuvrKit
import CoreData

extension MRManagedExerciseSession {
    
    static func findUploadableSessions(inManagedObjectContext managedObjectContext: NSManagedObjectContext) -> [MRManagedExerciseSession] {
        let fetchRequest = NSFetchRequest(entityName: "MRManagedExerciseSession")
        fetchRequest.predicate = NSPredicate(format: "(uploaded == false && completed = true)")
        
        return try! managedObjectContext.executeFetchRequest(fetchRequest) as! [MRManagedExerciseSession]
    }

    static func sessionsOnDate(date: NSDate, inManagedObjectContext managedObjectContext: NSManagedObjectContext) -> [MRManagedExerciseSession] {
        let fetchRequest = NSFetchRequest(entityName: "MRManagedExerciseSession")
        let midnightToday = date.dateOnly
        let midnightTomorrow = midnightToday.addDays(1)
        fetchRequest.predicate = NSPredicate(format: "(start >= %@ AND start < %@)", midnightToday, midnightTomorrow)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "start", ascending: false)]
        
        return try! managedObjectContext.executeFetchRequest(fetchRequest) as! [MRManagedExerciseSession]
    }
    
    static func sessionById(sessionId: String, inManagedObjectContext managedObjectContext: NSManagedObjectContext) -> MRManagedExerciseSession? {
        let fetchRequest = NSFetchRequest(entityName: "MRManagedExerciseSession")
        fetchRequest.predicate = NSPredicate(format: "(id == %@)", sessionId)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "start", ascending: false)]
        fetchRequest.fetchLimit = 1
        
        let result = try! managedObjectContext.executeFetchRequest(fetchRequest) as! [MRManagedExerciseSession]
        if result.count == 0 {
            return nil
        } else {
            return result[0]
        }
    }
    
    static func hasSessionsOnDate(date: NSDate, inManagedObjectContext managedObjectContext: NSManagedObjectContext) -> Bool {
        let fetchRequest = NSFetchRequest(entityName: "MRManagedExerciseSession")
        let midnightToday = date.dateOnly
        let midnightTomorrow = midnightToday.addDays(1)
        fetchRequest.predicate = NSPredicate(format: "(start >= %@ AND start < %@)", midnightToday, midnightTomorrow)
        fetchRequest.fetchLimit = 1
        
        return managedObjectContext.countForFetchRequest(fetchRequest).map { $0 > 0 } ?? false
        
    }
    
    static func insertNewObject(inManagedObjectContext managedObjectContext: NSManagedObjectContext) -> MRManagedExerciseSession {
        let mo = NSEntityDescription.insertNewObjectForEntityForName("MRManagedExerciseSession", inManagedObjectContext: managedObjectContext) as! MRManagedExerciseSession
        
        return mo
    }
    
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