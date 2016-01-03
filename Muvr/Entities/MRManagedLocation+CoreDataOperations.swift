import Foundation
import CoreData
import CoreLocation

extension MRManagedLocation {
    
    static func findAtLocation(location: CLLocation, inManagedObjectContext managedObjectContext: NSManagedObjectContext) -> MRManagedLocation? {
        let fetchRequest = NSFetchRequest(entityName: "MRManagedLocation")
        let latMin = location.coordinate.latitude - location.horizontalAccuracy
        let latMax = location.coordinate.latitude + location.horizontalAccuracy
        let lonMin = location.coordinate.longitude - location.horizontalAccuracy
        let lonMax = location.coordinate.longitude + location.horizontalAccuracy
        
        fetchRequest.predicate = NSPredicate(format: "(lat between (%@, %@) && lon between (%@, %@))", latMin, latMax, lonMin, lonMax)
        
        return (try! managedObjectContext.executeFetchRequest(fetchRequest) as! [MRManagedLocation]).first
    }
    
}
