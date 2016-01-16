import Foundation
import CoreData

extension MRManagedExerciseSession {
    @NSManaged var completed: Bool
    @NSManaged var end: NSDate?
    @NSManaged var exerciseType: String
    @NSManaged var id: String
    @NSManaged var sensorData: NSData?
    @NSManaged var start: NSDate
    @NSManaged var uploaded: Bool

    @NSManaged var location: MRManagedLocation?
    @NSManaged var exercises: NSSet
}
