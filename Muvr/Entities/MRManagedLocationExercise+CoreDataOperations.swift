import Foundation
import CoreData
import MuvrKit

extension MRManagedLocationExercise {
    
    static func insertNewObjectFromJSON(json: NSDictionary, location: MRManagedLocation, inManagedObjectContext managedObjectContext: NSManagedObjectContext) {
        guard let station = json["station"] as? String?,
            let stationProximityUUID = json["stationProximityUUID"] as? String?,
            let id = json["id"] as? MKExercise.Id,
            let properties = json["properties"] as? [AnyObject]?
            else { return }
        
        let mo = NSEntityDescription.insertNewObjectForEntityForName("MRManagedLocationExercise", inManagedObjectContext: managedObjectContext) as! MRManagedLocationExercise
        mo.station = station
        mo.id = id
        mo.stationProximityUUID = stationProximityUUID
        mo.location = location
        mo.properties = properties?.flatMap { MKExerciseProperty(json: $0) } ?? []
    }

    
}
