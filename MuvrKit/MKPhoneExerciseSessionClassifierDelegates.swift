import Foundation

public typealias MKExerciseWithLabels = (MKExercise, [MKExerciseLabel])

///
/// Implementations will receive the results of session classification and summarisation
///
public protocol MKSessionClassifierDelegate {
    
    ///
    /// Called when the session classification completes. The session continues even
    /// after the classification.
    ///
    /// - parameter session: the current snapshot of the session
    /// - parameter classified: the classified exercises
    /// - parameter sensorData: the sensor data collected so far
    ///
    func sessionClassifierDidClassify(session: MKExerciseSession, classified: [MKExerciseWithLabels], sensorData: MKSensorData)
    
    ///
    /// Called when the session classification estimates the exercise that has not yet ended.
    ///
    /// - parameter session: the current snapshot of the session
    /// - parameter estimated: the estimated exercises
    ///
    func sessionClassifierDidEstimate(session: MKExerciseSession, estimated: [MKExerciseWithLabels])
    
    ///
    /// The session has ended
    ///
    /// - parameter session: the session that has just ended
    /// - parameter sensorData: the sensor data from the entire session
    ///
    func sessionClassifierDidEnd(session: MKExerciseSession, sensorData: MKSensorData?)
        
    ///
    /// Called when the session starts
    ///
    /// - parameter session: the session that has just started
    ///
    func sessionClassifierDidStart(session: MKExerciseSession)
    
}
