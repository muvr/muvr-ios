import Foundation
import CoreData
import MuvrKit

extension MRAppDelegate {
    
    private func mkExerciseSession(mo: NSManagedObject) -> MKExerciseSession? {
        if let id = mo.valueForKey("id") as? String,
            let exerciseModelId = mo.valueForKey("exerciseModelId") as? String,
            let startDate = mo.valueForKey("startDate") as? NSDate {
                return MKExerciseSession(id: id, exerciseModelId: exerciseModelId, startDate: startDate, classifiedExercises: [])
        }
        return nil
    }
    
    func save(session session: MKExerciseSession, sensorData: MKSensorData?) {
        let entity = NSEntityDescription.entityForName("MKExerciseSession", inManagedObjectContext: managedObjectContext)!
        let ms = NSManagedObject(entity: entity, insertIntoManagedObjectContext: managedObjectContext)
        ms.setValue(session.startDate, forKey: "startDate")
        ms.setValue(session.id, forKey: "id")
        ms.setValue(session.exerciseModelId, forKey: "exerciseModelId")
        try! managedObjectContext.save()
    }
    
    func getSessionById(id: String) -> MKExerciseSession? {
        let fr = NSFetchRequest(entityName: "MKExerciseSession")
        fr.predicate = NSPredicate(format: "(id = %@)", id)
        let mo = try! managedObjectContext.executeFetchRequest(fr).first as? NSManagedObject
        return mo.flatMap(mkExerciseSession)
    }
    
    func getAllSessions() -> [MKExerciseSession] {
        let fr = NSFetchRequest(entityName: "MKExerciseSession")
        if let result = try! managedObjectContext.executeFetchRequest(fr) as? [NSManagedObject] {
            return result.flatMap(mkExerciseSession)
        }
        return []
    }
    
}
