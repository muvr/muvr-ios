import Foundation

/// Adds convenience initializer for constructing predicate for a 2D location
extension NSPredicate {
    
    ///
    /// Constructs a predicate for the given ``location``, assuming it is expressed as
    /// ``latitude`` and ``longitude`` properties; The filter is a box centered at
    /// ``location`` with 0.02 degrees per side. This is acceptable for coarse predicates
    /// over small area.
    ///
    /// - parameter location: the 2D location
    ///
    convenience init(location: MRLocationCoordinate2D) {
        let accuracy = 0.01
        let latMin = location.latitude - accuracy
        let latMax = location.latitude + accuracy
        let lonMin = location.longitude - accuracy
        let lonMax = location.longitude + accuracy
        
        self.init(format: "latitude >= %@ && latitude <= %@ && longitude >= %@ && longitude <= %@", argumentArray: [latMin, latMax, lonMin, lonMax])
    }
    
}
