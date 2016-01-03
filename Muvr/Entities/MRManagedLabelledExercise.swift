import Foundation
import CoreData
import MuvrKit

class MRManagedLabelledExercise: NSManagedObject {

    static func insertNewObject(into session: MRManagedExerciseSession, inManagedObjectContext managedObjectContext: NSManagedObjectContext) -> MRManagedLabelledExercise {
        let mo = NSEntityDescription.insertNewObjectForEntityForName("MRManagedLabelledExercise", inManagedObjectContext: managedObjectContext) as! MRManagedLabelledExercise
        mo.exerciseSession = session
        return mo
    }
    
    func isBefore(other: MRManagedClassifiedExercise) -> Bool {
        return start.compare(other.start) == .OrderedAscending
    }
    
    var label: MKLabelledExercise {
        return Label(from: self)
    }
    
    struct Label : MKLabelledExercise {
        let start: NSDate
        let exerciseId: MKExerciseId
        let duration: Double
        
        let repetitionsLabel: Int32
        let intensityLabel: MKExerciseIntensity
        let weightLabel: Double

        init(from: MRManagedLabelledExercise) {
            start = from.start
            exerciseId = from.exerciseId
            duration = from.duration
            repetitionsLabel = from.cdRepetitions
            intensityLabel = from.cdIntensity
            weightLabel = from.cdWeight
        }
        
    }

}

