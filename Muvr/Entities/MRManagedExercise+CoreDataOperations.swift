import Foundation
import CoreData
import MuvrKit

extension MRManagedExercise {
    
    static func insertNewObjectIntoSession(_ session: MRManagedExerciseSession, id: MKExercise.Id, exerciseType: MKExerciseType, labels: [MKExerciseLabel], offset: TimeInterval, duration: TimeInterval, inManagedObjectContext managedObjectContext: NSManagedObjectContext) -> MRManagedExercise {
        var mo = NSEntityDescription.insertNewObject(forEntityName: "MRManagedExercise", into: managedObjectContext) as! MRManagedExercise
        
        mo.id = id
        mo.exerciseType = exerciseType
        mo.offset = offset
        mo.duration = duration
        mo.session = session
        let insertedLabels: [MRManagedExerciseScalarLabel] = labels.map { label in
            switch label {
            case .intensity(let intensity):
                return MRManagedExerciseScalarLabel.insertNewObjectIntoExercise(mo, type: label.id, value: NSDecimalNumber(value: intensity), inManagedObjectContext: managedObjectContext)
            case .repetitions(let repetitions):
                return MRManagedExerciseScalarLabel.insertNewObjectIntoExercise(mo, type: label.id, value: NSDecimalNumber(value: repetitions), inManagedObjectContext: managedObjectContext)
            case .weight(let weight):
                return MRManagedExerciseScalarLabel.insertNewObjectIntoExercise(mo, type: label.id, value: NSDecimalNumber(value: weight), inManagedObjectContext: managedObjectContext)
            }
        }
        mo.scalarLabels = NSSet(array: insertedLabels)
        
        return mo
    }

}
