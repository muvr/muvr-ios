import Foundation
import CoreData

extension MRManagedExerciseSession {

    @NSManaged var exerciseModelId: String
    @NSManaged var id: String
    @NSManaged var locationId: String?
    @NSManaged var sensorData: NSData?
    @NSManaged var start: NSDate
    @NSManaged var labelledExercises: NSSet
    @NSManaged var classifiedExercises: NSSet
    @NSManaged var end: NSDate?
    @NSManaged var completed: Bool
    @NSManaged var uploaded: Bool

}
