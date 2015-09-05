import Foundation

typealias DeviceSession = NSUUID
typealias DeviceId = NSUUID

///
/// Implement to receive data and session identities
///
protocol MRDeviceSessionDelegate {
    
    ///
    /// Called when a sensor data (in the Lift format) is received from the device. The data is complete
    /// multiple of packets; it can be sent directly to the server for decoding.
    ///
    /// @param session the device session
    /// @param deviceId the device from which the data was received
    /// @time the device time
    /// @param data the sensor data, aligned to packets
    ///
    func deviceSession(session: DeviceSession, sensorDataReceivedFrom deviceId: DeviceId, atDeviceTime time: CFAbsoluteTime, data: NSData)
    
    ///
    /// The following functions refer to _exercise index_. It is an index in the ``resistance_exercise_t`` array, which has been
    /// previously set by calling ``MRRawPebbleDeviceSession.notifySimpleClassificationCompleted`` function.
    ///
    
    ///
    /// Called when the user accepts the exercise with the index. The user has accepted the classification, and we
    /// therefore have a confirmed true positive.
    ///
    /// @param session the device session
    /// @param index the selected exercise number
    /// @param deviceId the device sending the notification
    ///
    func deviceSession(session: DeviceSession, exerciseAccepted index: UInt8, from deviceId: DeviceId)
    
    ///
    /// Called when the user rejects the exercise with the index. The user has rejected the classification, 
    /// and we have a negative sample.
    ///
    /// @param session the device session
    /// @param index the selected exercise number
    /// @param deviceId the device sending the notification
    ///
    func deviceSession(session: DeviceSession, exerciseRejected index: UInt8, from deviceId: DeviceId)
    
    ///
    /// Called when the user accepts the exercise with the index by letting it time out. The user has accepted the
    /// classification, and we therefore have a confirmed true positive.
    ///
    /// @param session the device session
    /// @param index the selected exercise number
    /// @param deviceId the device sending the notification
    ///
    func deviceSession(session: DeviceSession, exerciseSelectionTimedOut index: UInt8, from deviceId: DeviceId)
    
    ///
    /// Called when the user selects the exercise that is being trained.
    ///
    /// @param session the device session
    /// @param deviceId the device sending the notification
    ///
    func deviceSession(session: DeviceSession, exerciseTrainingCompletedFrom deviceId: DeviceId)
    
    ///
    /// Called when the completes explicitly exercise
    ///
    /// @param session the device session
    /// @param deviceId the device sending the notification
    ///
    func deviceSession(session: DeviceSession, exerciseCompletedFrom deviceId: DeviceId)
    
    ///
    /// Called when a sensor data is not received, but was expected. This typically indicates a
    /// problem with the BLE connection
    ///
    func deviceSession(session: DeviceSession, sensorDataNotReceivedFrom deviceId: DeviceId)
    
    ///
    /// Called when the device ends the session. Typically, a user presses a button on the device
    /// to stop the session.
    ///
    /// @param deviceSession the device session
    ///
    func deviceSession(session: DeviceSession, endedFrom deviceId: DeviceId)
}
