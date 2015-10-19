import Foundation

///
public protocol MKSensorDataConnectivityDelegate {
    
    ///
    /// Called when the application receives new exercise models
    ///
    /// - parameter accumulated: the accumulated sensor data
    /// - parameter new: only the new received block
    ///
    func sensorDataConnectivityDidReceiveSensorData(accumulated accumulated: MKSensorData, new: MKSensorData)
    
}

///
public protocol MKExerciseConnectivitySessionDelegate {
   
    ///
    /// Called with the watch starts the session with the selected ``exerciseModelId``.
    ///
    /// - parameter exerciseModelId: the exercise model id
    /// - parameter session: the session identity
    ///
    func exerciseConnectivitySessionDidStart(sessionId sessionId: String, exerciseModelId: MKExerciseModelId)
    
    ///
    /// Called when the watch ends the session
    ///
    func exerciseConnectivitySessionDidEnd(sessionId sessionId: String)
    
}
