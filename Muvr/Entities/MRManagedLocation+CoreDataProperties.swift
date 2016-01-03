import Foundation
import CoreData

extension MRManagedLocation {

    @NSManaged var lat: Double
    @NSManaged var lon: Double
    @NSManaged var name: String
    @NSManaged var id: String
    @NSManaged var link: String?
    @NSManaged var labels: NSSet

}
