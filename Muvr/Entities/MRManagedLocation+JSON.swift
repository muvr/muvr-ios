import Foundation
import CoreData

extension MRManagedLocation {
    
    static func upsertObject(from json: NSDictionary, inManagedObjectContext managedObjectContext: NSManagedObjectContext) throws {
        guard let id = json["id"] as? String,
            let lat = json["lat"] as? NSNumber,
            let lon = json["lon"] as? NSNumber,
            let name = json["name"] as? String else { return }
        
        let fetchRequest = NSFetchRequest(entityName: "MRManagedExerciseSession")
        fetchRequest.predicate = NSPredicate(format: "(id = %@)", id)
        if let existing = try managedObjectContext.executeFetchRequest(fetchRequest).first as? NSManagedObject {
            managedObjectContext.deleteObject(existing)
        }
        
        let mo = NSEntityDescription.insertNewObjectForEntityForName("MRManagedLocation", inManagedObjectContext: managedObjectContext) as! MRManagedLocation
        
        mo.lat = lat.doubleValue
        mo.lon = lon.doubleValue
        mo.name = name
        mo.id = id
        
        (json["labels"] as? NSArray)?.forEach { e in
            if let l = e as? NSDictionary {
                MRManagedLocationLabel.insertNewObject(from: l, at: mo, inManagedObjectContext: managedObjectContext)
            }
        }
    }
    
}
