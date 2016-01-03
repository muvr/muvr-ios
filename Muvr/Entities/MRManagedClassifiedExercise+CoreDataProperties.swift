import Foundation
import CoreData

extension MRManagedClassifiedExercise {

    @NSManaged var start: NSDate
    @NSManaged var confidence: Double
    @NSManaged var duration: Double
    @NSManaged var exerciseId: String
    
    @NSManaged var cdIntensity: NSNumber?
    @NSManaged var cdRepetitions: NSNumber?
    @NSManaged var cdWeight: NSNumber?
    
    @NSManaged var exerciseSession: MRManagedExerciseSession?

}
