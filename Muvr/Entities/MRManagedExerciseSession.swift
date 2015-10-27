import Foundation
import CoreData
import MuvrKit

class MRManagedExerciseSession: NSManagedObject {
    
    static func sessionsOnDate(date: NSDate, inManagedObjectContext managedObjectContext: NSManagedObjectContext) -> [MRManagedExerciseSession] {
        let fetchRequest = NSFetchRequest(entityName: "MRManagedExerciseSession")
        let midnightToday = date.dateOnly
        let midnightTomorrow = midnightToday.addDays(1)
        fetchRequest.predicate = NSPredicate(format: "(startDate >= %@ AND startDate < %@)", midnightToday, midnightTomorrow)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "startDate", ascending: false)]
        
        return try! managedObjectContext.executeFetchRequest(fetchRequest) as! [MRManagedExerciseSession]
    }
    
    static func insertNewObject(inManagedObjectContext managedObjectContext: NSManagedObjectContext) -> MRManagedExerciseSession {
        let mo = NSEntityDescription.insertNewObjectForEntityForName("MRManagedExerciseSession", inManagedObjectContext: managedObjectContext) as! MRManagedExerciseSession
        
        return mo
    }
    
    static func insertNewObject(from session: MKExerciseSession, inManagedObjectContext managedObjectContext: NSManagedObjectContext) -> MRManagedExerciseSession {
        let mo = insertNewObject(inManagedObjectContext: managedObjectContext)
        mo.id = session.id
        mo.startDate = session.startDate
        mo.exerciseModelId = session.exerciseModelId
        
        return mo
    }
    
}
