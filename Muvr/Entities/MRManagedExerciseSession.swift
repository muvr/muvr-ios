import Foundation
import CoreData
import MuvrKit

class MRManagedExerciseSession: NSManagedObject {
    private var plan: MKExercisePlan = MKExercisePlan()
    
    ///
    /// Returns the suggested exercises at the current session state
    ///
    var suggestedExercises: [MKPlannedExercise] {
        let modelExercises = MRAppDelegate.sharedDelegate().modelStore.exerciseIds(model: exerciseModelId).map { MKPlannedExercise(exerciseId: $0) }
        let planExercises = plan.nextExercises
        let notPlannedModelExercises = modelExercises.filter { me in
            return !planExercises.contains { pe in pe.exerciseId == me.exerciseId }
        }
        return planExercises + notPlannedModelExercises
    }
    
    ///
    /// Adds the completed exercise to the plan.
    ///
    /// - parameter exercise: the completed exercise
    ///
    func addExercise(exercise: MKPlannedExercise) {
        plan.addExercise(exercise)
    }

    ///
    /// All classified exercises grouped into sets of same exercises
    ///
    var sets: [[MRManagedClassifiedExercise]] {
        get {
            var em: [MKExerciseId : [MRManagedClassifiedExercise]] = [:]
            classifiedExercises.forEach { x in
                if let l = em[x.exerciseId] {
                    em[x.exerciseId] = l + [x as! MRManagedClassifiedExercise]
                } else {
                    em[x.exerciseId] = [x as! MRManagedClassifiedExercise]
                }
            }
            return em.values.sort { l, r in l.first!.exerciseId > r.first!.exerciseId }
        }
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
        
        return managedObjectContext.countForFetchRequest(fetchRequest).map { count in count > 0 } ?? false
        
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
        
        return mo
    }
    
}
