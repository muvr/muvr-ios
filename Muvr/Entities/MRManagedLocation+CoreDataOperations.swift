import Foundation
import CoreData
import CoreLocation

extension MRManagedLocation {
    
    static func findAtLocation(location: CLLocation, inManagedObjectContext managedObjectContext: NSManagedObjectContext) -> MRManagedLocation? {
        let fetchRequest = NSFetchRequest(entityName: "MRManagedLocation")
        let accuracy = 0.01
        let latMin = location.coordinate.latitude - accuracy
        let latMax = location.coordinate.latitude + accuracy
        let lonMin = location.coordinate.longitude - accuracy
        let lonMax = location.coordinate.longitude + accuracy
        
        fetchRequest.predicate = NSPredicate(format: "lat >= %@ && lat <= %@ && lon >= %@ && lon <= %@", argumentArray: [latMin, latMax, lonMin, lonMax])
        
        return (try! managedObjectContext.executeFetchRequest(fetchRequest) as! [MRManagedLocation]).first
    }
    
}
