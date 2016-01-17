import Foundation
import CoreData
import MuvrKit

extension MRManagedExercise {
    
    static func insertNewObjectIntoSession(session: MRManagedExerciseSession, id: MKExercise.Id, exerciseType: MKExerciseType, labels: [MKExerciseLabel], offset: NSTimeInterval, duration: NSTimeInterval, inManagedObjectContext managedObjectContext: NSManagedObjectContext) {
        var mo = NSEntityDescription.insertNewObjectForEntityForName("MRManagedExercise", inManagedObjectContext: managedObjectContext) as! MRManagedExercise
        
        mo.id = id
        mo.exerciseType = exerciseType
        mo.offset = offset
        mo.duration = duration
        mo.session = session
        
        for label in labels {
            switch label {
            case .Intensity(let intensity):
                MRManagedExerciseScalarLabel.insertNewObjectIntoExercise(mo, type: label.id, value: NSDecimalNumber(double: intensity), inManagedObjectContext: managedObjectContext)
            case .Repetitions(let repetitions):
                MRManagedExerciseScalarLabel.insertNewObjectIntoExercise(mo, type: label.id, value: NSDecimalNumber(integer: repetitions), inManagedObjectContext: managedObjectContext)
            case .Weight(let weight):
                MRManagedExerciseScalarLabel.insertNewObjectIntoExercise(mo, type: label.id, value: NSDecimalNumber(double: weight), inManagedObjectContext: managedObjectContext)
            }
        }
    }

}
