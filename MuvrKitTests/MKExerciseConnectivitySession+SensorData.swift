import Foundation
@testable import MuvrKit

///
/// Adds a convenience function that copies this instance with the given ``MKSensorData``.
///
extension MKExerciseConnectivitySession {
    
    ///
    /// Returns a copy of self with ``sensorData`` set to the parameter.
    ///
    /// - parameter sensorData: the new ``MKSensorData``
    /// - returns: the copied instance
    ///
    func withData(sensorData: MKSensorData) -> MKExerciseConnectivitySession {
        var x = MKExerciseConnectivitySession(id: self.id, exerciseModelId: self.exerciseModelId, start: self.start)
        x.sensorData = sensorData
        return x
    }
    
}
