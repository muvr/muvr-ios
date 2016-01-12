import Foundation
import CoreData

extension MRManagedLocation {

    @NSManaged var longitude: Double
    @NSManaged var latitude: Double
    @NSManaged var name: String
    @NSManaged var id: String
    @NSManaged var link: String?
    @NSManaged var labels: NSSet

}
