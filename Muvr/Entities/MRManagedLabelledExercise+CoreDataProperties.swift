import Foundation
import CoreData
import MuvrKit

extension MRManagedLabelledExercise {

    @NSManaged var duration: Double
    @NSManaged var exerciseId: String
    @NSManaged var start: NSDate
    
    @NSManaged var cdIntensity: Double
    @NSManaged var cdRepetitions: Int32
    @NSManaged var cdWeight: Double

    @NSManaged var exerciseSession: MRManagedExerciseSession?

}
