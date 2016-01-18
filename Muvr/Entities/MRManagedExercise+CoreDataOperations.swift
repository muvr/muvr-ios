import Foundation
import CoreData
import MuvrKit

extension MRManagedExercise {
    
    static func insertNewObjectIntoSession(session: MRManagedExerciseSession, id: MKExercise.Id, exerciseType: MKExerciseType, labels: [MKExerciseLabel], offset: NSTimeInterval, duration: NSTimeInterval, inManagedObjectContext managedObjectContext: NSManagedObjectContext) -> MRManagedExercise {
        var mo = NSEntityDescription.insertNewObjectForEntityForName("MRManagedExercise", inManagedObjectContext: managedObjectContext) as! MRManagedExercise
        
        mo.id = id
        mo.exerciseType = exerciseType
        mo.offset = offset
        mo.duration = duration
        mo.session = session
        let insertedLabels: [MRManagedExerciseScalarLabel] = labels.map { label in
            switch label {
            case .Intensity(let intensity):
                return MRManagedExerciseScalarLabel.insertNewObjectIntoExercise(mo, type: label.id, value: NSDecimalNumber(double: intensity), inManagedObjectContext: managedObjectContext)
            case .Repetitions(let repetitions):
                return MRManagedExerciseScalarLabel.insertNewObjectIntoExercise(mo, type: label.id, value: NSDecimalNumber(integer: repetitions), inManagedObjectContext: managedObjectContext)
            case .Weight(let weight):
                return MRManagedExerciseScalarLabel.insertNewObjectIntoExercise(mo, type: label.id, value: NSDecimalNumber(double: weight), inManagedObjectContext: managedObjectContext)
            }
        }
        mo.scalarLabels = NSSet(array: insertedLabels)
        
        return mo
    }

}
