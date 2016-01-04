import Foundation
import CoreData

extension MRManagedLocationLabel {
    
    static func insertNewObject(from json: NSDictionary, at location: MRManagedLocation, inManagedObjectContext managedObjectContext: NSManagedObjectContext) {
        guard let station = json["station"] as? String?,
              let stationProximityUUID = json["stationProximityUUID"] as? String?,
              let exerciseId = json["exerciseId"] as? String,
              let minWeight = json["minWeight"] as? NSNumber,
              let maxWeight = json["maxWeight"] as? NSNumber?,
              let weightIncrement = json["weightIncrement"] as? NSNumber?
            else { return }
        
        let mo = NSEntityDescription.insertNewObjectForEntityForName("MRManagedLocationLabel", inManagedObjectContext: managedObjectContext) as! MRManagedLocationLabel
        mo.station = station
        mo.exerciseId = exerciseId
        mo.minWeight = minWeight.doubleValue
        mo.maxWeight = maxWeight
        mo.weightIncrement = weightIncrement
        mo.stationProximityUUID = stationProximityUUID
        mo.location = location
    }
    
}
