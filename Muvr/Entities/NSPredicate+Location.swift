import Foundation

/// Adds convenience initializer for constructing predicate for a 2D location
extension NSPredicate {
    
    ///
    /// Constructs a predicate for the given ``location``, assuming it is expressed as
    /// ``latitude`` and ``longitude`` properties; The filter is a box centered at
    /// ``location`` with 0.02 degrees per side. This is acceptable for coarse predicates
    /// over small area.
    ///
    /// - parameter latitude: the latitude
    /// - parameter longitude: the longitude
    ///
    convenience init(latitude: Double, longitude: Double) {
        let accuracy = 0.01
        let latMin = latitude - accuracy
        let latMax = latitude + accuracy
        let lonMin = longitude - accuracy
        let lonMax = longitude + accuracy
        
        self.init(format: "latitude >= %@ && latitude <= %@ && longitude >= %@ && longitude <= %@", argumentArray: [latMin, latMax, lonMin, lonMax])
    }
    
    ///
    /// Constructs a predicate for the given ``location``, assuming it is expressed as
    /// ``latitude`` and ``longitude`` properties; The filter is a box centered at
    /// ``location`` with 0.02 degrees per side. This is acceptable for coarse predicates
    /// over small area.
    ///
    /// - parameter location: the 2D location
    ///
    convenience init(location: MRLocationCoordinate2D) {
        self.init(latitude: location.latitude, longitude: location.longitude)
    }
    
}
