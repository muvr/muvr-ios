import Foundation
import CoreData
import CoreLocation

extension MRManagedLocation {
    
    static func findAtLocation(location: MRLocationCoordinate2D, inManagedObjectContext managedObjectContext: NSManagedObjectContext) -> MRManagedLocation? {
        let fetchRequest = NSFetchRequest(entityName: "MRManagedLocation")
        fetchRequest.predicate = NSPredicate(location: location)
        
        return (try! managedObjectContext.executeFetchRequest(fetchRequest) as! [MRManagedLocation]).first
    }
    
}
