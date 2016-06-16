import Foundation

///
/// The stored properties of an ``MRManagedLabelsPredictor``
///
extension MRManagedLabelsPredictor: MRManagedExerciseType {

    ///
    /// the ``MKLabelsPredictor`` serialised into JSON NSData
    ///
    @NSManaged var data: Data
    ///
    /// the latitude linked to this predictor
    ///
    @NSManaged var latitude: NSNumber?
    ///
    /// the longitude linked to this predictor
    ///
    @NSManaged var longitude: NSNumber?
    
}
