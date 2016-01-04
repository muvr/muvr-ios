import Foundation
import CoreData
import MuvrKit

class MRManagedClassifiedExercise: NSManagedObject {
    
    static func insertNewObject(inManagedObjectContext managedObjectContext: NSManagedObjectContext) -> MRManagedClassifiedExercise {
        let mo = NSEntityDescription.insertNewObjectForEntityForName("MRManagedClassifiedExercise", inManagedObjectContext: managedObjectContext) as! MRManagedClassifiedExercise
        return mo
    }

    static func insertNewObject(from classifiedExercise: MKClassifiedExercise, into session: MRManagedExerciseSession, inManagedObjectContext managedObjectContext: NSManagedObjectContext) -> MRManagedClassifiedExercise {
        let mo = insertNewObject(inManagedObjectContext: managedObjectContext)
        
        mo.exerciseSession = session
        mo.start = session.start.dateByAddingTimeInterval(classifiedExercise.offset)
        mo.confidence = classifiedExercise.confidence
        mo.duration = classifiedExercise.duration
        mo.exerciseId = classifiedExercise.exerciseId
        mo.cdRepetitions = classifiedExercise.repetitions.map { NSNumber(int: $0) }
        mo.cdIntensity = classifiedExercise.intensity
        mo.cdWeight = classifiedExercise.weight
        
        return mo
    }
    
    func isBefore(other: MRManagedClassifiedExercise) -> Bool {
        return start.compare(other.start) == .OrderedAscending
    }

}
