import Foundation
import CoreData
import MuvrKit

///
/// Adds CD operations
///
extension MRManagedScalarPredictor {
    
    ///
    /// Looks up an MRManagedScalarPredictor for the given ``type`` and ``location`` where both values match exactly.
    /// - parameter type: the predictor type
    /// - parameter location: the (geo)location
    /// - parameter managedObjectContext: the MOC
    /// - returns: the matching MRManagedScalarPredictor
    ///
    static func exactScalarPredictorFor(type: String, location: MRLocationCoordinate2D?, inManagedObjectContext managedObjectContext: NSManagedObjectContext) -> MRManagedScalarPredictor? {
        let fetchRequest = NSFetchRequest(entityName: "MRManagedScalarPredictor")
        var predicate = NSPredicate(format: "type = %@", type)
        if let location = location {
            predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate, NSPredicate(location: location)])
        }
        fetchRequest.fetchLimit = 1
        
        return (try! managedObjectContext.executeFetchRequest(fetchRequest)).first as? MRManagedScalarPredictor
    }
    
    ///
    /// Looks up an MRManagedScalarPredictor for the given ``type`` and ``location`` where both values match exactly first,
    /// then falling back on any location.
    /// - parameter type: the predictor type
    /// - parameter location: the (geo)location
    /// - parameter managedObjectContext: the MOC
    /// - returns: the matching MRManagedScalarPredictor
    ///
    static func scalarPredictorFor(type: String, location: MRLocationCoordinate2D?, inManagedObjectContext managedObjectContext: NSManagedObjectContext) -> MRManagedScalarPredictor? {
        if let exact = exactScalarPredictorFor(type, location: location, inManagedObjectContext: managedObjectContext) {
            return exact
        } else if location != nil {
            return exactScalarPredictorFor(type, location: nil, inManagedObjectContext: managedObjectContext)
        } else {
            return nil
        }
    }
    
    ///
    /// Upserts the data in MRManagedScalarPredictor ``data`` for the given ``type`` and ``location``.
    /// - parameter type: the predictor type
    /// - parameter location: the location
    /// - parameter data: the data
    /// - parameter managedObjectContext: the MOC
    ///
    static func upsertScalarPredictor(type: String, location: MRLocationCoordinate2D?, data: NSData, inManagedObjectContext managedObjectContext: NSManagedObjectContext) {
        if let existing = exactScalarPredictorFor(type, location: location, inManagedObjectContext: managedObjectContext) {
            existing.data = data
        } else {
            let mo = NSEntityDescription.insertNewObjectForEntityForName("MRManagedScalarPredictor", inManagedObjectContext: managedObjectContext) as! MRManagedScalarPredictor
            mo.type = type
            mo.data = data
            mo.latitude = location?.latitude
            mo.longitude = location?.longitude
        }
    }
    
}
