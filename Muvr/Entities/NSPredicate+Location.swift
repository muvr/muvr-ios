import Foundation

extension NSPredicate {
    
    convenience init(location: MRLocationCoordinate2D) {
        let accuracy = 0.01
        let latMin = location.latitude - accuracy
        let latMax = location.latitude + accuracy
        let lonMin = location.longitude - accuracy
        let lonMax = location.longitude + accuracy
        
        self.init(format: "latitude >= %@ && latitude <= %@ && longitude >= %@ && longitude <= %@", argumentArray: [latMin, latMax, lonMin, lonMax])
    }
    
}