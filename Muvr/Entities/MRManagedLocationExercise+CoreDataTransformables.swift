import Foundation
import CoreData
import MuvrKit

extension MRManagedLocationExercise {
    
    /// Transforms the underlying ``properties`` attribute
    /// to the expected type ``[MKExerciseProperty]?``
    var properties: [MKExerciseProperty] {
        get {
            if let raw = value(forKey: "properties") as? [AnyObject] {
                return raw.flatMap { MKExerciseProperty(jsonObject: $0) }
            }
            return []
        }
        set {
            setValue(newValue.map { $0.jsonObject }, forKey: "properties")
        }
    }
    
}
