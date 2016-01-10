import Foundation
import CoreData
import MuvrKit
import CoreLocation

///
/// Provides the CoreData operations
///
extension MRManagedExercisePlan {

    ///
    /// Loads the most specific (matching all properties), falling back on more generic (matching fewer properties),
    /// exercise plan in the given managedObjectContext.
    ///
    /// - parameter type: the exercise type to find the plan for
    /// - parameter location: the plan's location
    /// - parameter date: the plan's date
    /// - parameter managedObjectContext: the MOC
    /// - returns: the loaded plan; empty plan if no plan could be found
    ///
    static func planForExerciseType(type: MKExerciseType, location: CLLocation?, date: NSDate,
        inManagedObjectContext managedObjectContext: NSManagedObjectContext) -> MKExercisePlan<MKExerciseId> {
        
        // TODO: Implement properly
            
        let p = MKExercisePlan<MKExerciseId>()
        
        // at the cable machines
        for _ in 0..<10 {
            p.insert("resistanceTargeted:arms/biceps-curl")
            p.insert("resistanceTargeted:arms/triceps-extension")
            p.insert("resistanceTargeted:arms/barbell-biceps-curl")
            p.insert("resistanceTargeted:arms/triceps-pushdown")
        }
        
        return p
    }
    
    
}
