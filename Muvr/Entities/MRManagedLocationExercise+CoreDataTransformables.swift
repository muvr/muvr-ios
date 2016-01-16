import Foundation
import CoreData
import MuvrKit

extension MRManagedLocationExercise {
    
    /// Transforms the underlying ``properties`` attribute
    /// to the expected type ``[MKExerciseProperty]?``
    var properties: [MKExerciseProperty]? {
        get {
            if let raw = valueForKey("properties") as? [AnyObject] {
                return raw.flatMap { MKExerciseProperty(json: $0) }
            }
            return nil
        }
        set {
            setValue(newValue?.map { $0.json }, forKey: "properties")
        }
    }
    
}