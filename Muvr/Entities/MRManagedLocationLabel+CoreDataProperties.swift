import Foundation
import CoreData

extension MRManagedLocationLabel {

    @NSManaged var station: String?
    @NSManaged var exerciseId: String?
    @NSManaged var minWeight: Double
    @NSManaged var maxWeight: NSDecimalNumber?
    @NSManaged var weightIncrement: NSDecimalNumber?
    @NSManaged var location: MRManagedLocation

}
