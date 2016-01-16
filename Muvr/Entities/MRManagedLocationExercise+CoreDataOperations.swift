import Foundation
import CoreData

extension MRManagedLocationExercise {
    
    static func insertNewObjectFromJSON(json: NSDictionary, location: MRManagedLocation, inManagedObjectContext managedObjectContext: NSManagedObjectContext) {
        //fatalError()
//        guard let station = json["station"] as? String?,
//            let stationProximityUUID = json["stationProximityUUID"] as? String?,
//            let exerciseId = json["exerciseId"] as? String,
//            let minWeight = json["minWeight"] as? NSNumber?,
//            let maxWeight = json["maxWeight"] as? NSNumber?,
//            let weightIncrement = json["weightIncrement"] as? NSNumber?
//            else { return }
//        
//        let mo = NSEntityDescription.insertNewObjectForEntityForName("MRManagedLocationLabel", inManagedObjectContext: managedObjectContext) as! MRManagedLocationExercise
//        mo.station = station
//        mo.exerciseId = exerciseId
//        mo.minWeight = minWeight
//        mo.maxWeight = maxWeight
//        mo.weightIncrement = weightIncrement
//        mo.stationProximityUUID = stationProximityUUID
//        mo.location = location
    }

    
}
