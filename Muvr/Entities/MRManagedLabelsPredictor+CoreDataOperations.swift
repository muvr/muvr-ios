import Foundation
import CoreData
import MuvrKit

///
/// CoreData operations to save/fetch ``MRManagedLabelsPredictor``
///
extension MRManagedLabelsPredictor {
    
    ///
    /// Looks up an MRManagedLabelsPredictor for the given ``exercise type`` and ``location`` where both values match exactly.
    /// - parameter location: the (geo)location
    /// - parameter managedObjectContext: the MOC
    /// - returns: the matching MRManagedLabelsPredictor
    ///
    static func exactPredictorFor(location location: MRLocationCoordinate2D?, sessionExerciseType: MKExerciseType?, inManagedObjectContext managedObjectContext: NSManagedObjectContext) -> MRManagedLabelsPredictor? {
        let fetchRequest = NSFetchRequest(entityName: "MRManagedLabelsPredictor")
        var predicates: [NSPredicate] = []
        if let location = location {
            predicates.append(NSPredicate(location: location))
        }
        if let sessionExerciseType = sessionExerciseType {
            predicates.append(NSPredicate(exerciseType: sessionExerciseType))
        }
        if !predicates.isEmpty {
            fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        }
        fetchRequest.fetchLimit = 1
        
        return (try! managedObjectContext.executeFetchRequest(fetchRequest)).first as? MRManagedLabelsPredictor
    }
    
    ///
    /// Looks up an MRManagedLabelsPredictor for the given ``exercise type`` and ``location`` where both values match exactly first,
    /// then falling back on any location.
    /// - parameter location: the (geo)location
    /// - parameter managedObjectContext: the MOC
    /// - returns: the matching MRManagedLabelsPredictor
    ///
    static func predictorFor(location location: MRLocationCoordinate2D?, sessionExerciseType: MKExerciseType?, inManagedObjectContext managedObjectContext: NSManagedObjectContext) -> MRManagedLabelsPredictor? {
        if let exact = exactPredictorFor(location: location, sessionExerciseType: sessionExerciseType, inManagedObjectContext: managedObjectContext) {
            return exact
        } else if location != nil {
            return exactPredictorFor(location: nil, sessionExerciseType: sessionExerciseType, inManagedObjectContext: managedObjectContext)
        } else if sessionExerciseType != nil {
            return exactPredictorFor(location: nil, sessionExerciseType: nil, inManagedObjectContext: managedObjectContext)
        } else {
            return nil
        }
    }
    
    ///
    /// Upserts the data in MRManagedLabelsPredictor ``data`` for the given ``exercise type`` and ``location``.
    /// - parameter location: the location
    /// - parameter data: the data
    /// - parameter managedObjectContext: the MOC
    ///
    static func upsertPredictor(location location: MRLocationCoordinate2D?, sessionExerciseType: MKExerciseType, data: NSData, inManagedObjectContext managedObjectContext: NSManagedObjectContext) {
        if let existing = exactPredictorFor(location: location, sessionExerciseType: sessionExerciseType, inManagedObjectContext: managedObjectContext) {
            existing.data = data
        } else {
            var mo = NSEntityDescription.insertNewObjectForEntityForName("MRManagedLabelsPredictor", inManagedObjectContext: managedObjectContext) as! MRManagedLabelsPredictor
            mo.data = data
            mo.latitude = location?.latitude
            mo.longitude = location?.longitude
            mo.exerciseType = sessionExerciseType
        }
    }
    
}