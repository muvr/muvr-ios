import Foundation
import CoreData
import MuvrKit

///
/// Protocol that is fully implemented by ``NSManagedObject``, used here
/// as a marker interface for ``NSManagedObject`` subclasses that include
/// the ``exerciseType: String`` attribute, which the application wishes
/// to use as ``MKExerciseType``.
///
/// To construct predicates for the ``managedExerciseType``, consider using
/// the ``NSPredicate(exerciseType:)`` convenience initializer.
///
protocol MRManagedExerciseType {
    
    // See NSObject.valueForKey
    func valueForKey(key: String) -> AnyObject?
    
    // See NSObject.setValue
    func setValue(value: AnyObject?, forKey key: String)
    
}

///
/// Converts the value in ``managedExerciseType`` to values of type
/// ``MKExerciseType``.
///
extension MRManagedExerciseType {
    
    var exerciseType: MKExerciseType {
        get {
            let rawValue = valueForKey("exerciseType")
            if let value = rawValue as? String,
               let exerciseType = MKExerciseType(exerciseId: value) {
                return exerciseType
            }
            fatalError("\(rawValue) cannot be converted to MKExerciseType.")
        }
        set {
            setValue(newValue.exerciseIdPrefix, forKey: "exerciseType")
        }
    }
    
}

extension NSPredicate {
    /*
    if case .ResistanceTargeted(let muscleGroups) = exerciseType {
    predicate =
    NSCompoundPredicate(andPredicateWithSubpredicates: [
    predicate,
    NSPredicate(format: "SUBQUERY(muscleGroups, $mg, $mg.value IN %@).@count = %d", muscleGroups.map { $0.id }, muscleGroups.count)
    //NSPredicate(format: "muscleGroups.value in %@", muscleGroups.map { $0.id })
    ])
    }
    */
    
    convenience init(exerciseType: MKExerciseType) {
        self.init(format: "exerciseType = %@", exerciseType.exerciseIdPrefix)
    }
    
}
