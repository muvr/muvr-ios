import Foundation
@testable import MuvrKit

extension MKExerciseConnectivitySession {
    
    func withData(sensorData: MKSensorData) -> MKExerciseConnectivitySession {
        var x = MKExerciseConnectivitySession(id: self.id, exerciseModelId: self.exerciseModelId, startDate: self.startDate)
        x.sensorData = sensorData
        return x
    }
    
}
