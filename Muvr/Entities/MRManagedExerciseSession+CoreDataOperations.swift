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

}
