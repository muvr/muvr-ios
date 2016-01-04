import Foundation
import CoreData

extension MRManagedLocationLabel {

    @NSManaged var station: String?
    @NSManaged var stationProximityUUID: String?
    @NSManaged var exerciseId: String
    @NSManaged var minWeight: NSNumber?
    @NSManaged var maxWeight: NSNumber?
    @NSManaged var weightIncrement: NSNumber?
    @NSManaged var location: MRManagedLocation

}
