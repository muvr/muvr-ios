import Foundation
import CoreLocation

extension CLBeacon {
    
    ///
    /// The proximity score as a combination of proximity and its accuracy:
    /// the nearest and most accurate sensors have the best score.
    ///
    var proximityScore: Double {
        get {
            if proximity == CLProximity.Unknown { return 0 }
            // 2 + 2
            // 1 + 0.4
            return 1.0 / Double(proximity.rawValue * 10) + accuracy
        }
    }
    
}
