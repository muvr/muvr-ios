import Foundation

public typealias MKExerciseWithLabels = (MKExercise, [MKExerciseLabel])

public typealias MKExerciseProbability = (MKExercise.Id, Double)

///
/// A trigger that caused the ``sessionClassifierDidStartExercise`` method to be called. The
/// implementations of this delegate method can decide to filter the reasons and only accept
/// the ones that are deemed to be strong enough to actually progress the application's state
/// towards "exercising".
///
public enum MKSessionClassifierDelegateStartTrigger : Equatable {
    /// Motion from sensor detected
    case motionDetected
    /// A setup movement detected, the ``exercises`` are exercises that have been setup with
    /// their probabilities, ordered by the second element
    /// - parameter exercises: the exercise ids that matched the setup move
    case setupDetected(exercises: [MKExerciseProbability])
}

private func epe(l: MKExerciseProbability, r: MKExerciseProbability) -> Bool {
    return l.0 == r.0 && l.1 == r.1
}

public func ==(lhs: MKSessionClassifierDelegateStartTrigger, rhs: MKSessionClassifierDelegateStartTrigger) -> Bool {
    switch (lhs, rhs) {
    case (.motionDetected, .motionDetected): return true
    case (.setupDetected(let l), .setupDetected(let r)):
        if r.count != l.count { return false }
        for i in 0..<l.count {
            if !epe(l: l[i], r: r[i]) { return false }
        }
        return true
    default: return false
    }
}

///
/// A trigger that caused the ``sessionClassifierDidEndExercise`` method to be called. The
/// implementations of this delegate method can decide to filter the reasons and only accept
/// the ones that are deemed to be strong enough to actually progress the application's state
/// towards "not exercising".
///
public enum MKSessionClassifierDelegateEndTrigger : Equatable {
    /// Motion from the sensors has stopped
    case noMotionDetected
    /// The previously stable repetitive movement from the sensors has diverged
    case motionDiverged
    /// An ending movement detected, the ``exercises`` are exercises that have been setup with
    /// their probabilities, ordered by the second element
    /// - parameter exercises: the exercise ids that matched the ending move
    case endDetected(exercises: [MKExerciseProbability])
}

public func ==(lhs: MKSessionClassifierDelegateEndTrigger, rhs: MKSessionClassifierDelegateEndTrigger) -> Bool {
    switch (lhs, rhs) {
    case (.noMotionDetected, .noMotionDetected): return true
    case (.motionDiverged, .motionDiverged): return true
    case (.endDetected(let l), .endDetected(let r)):
        if r.count != l.count { return false }
        for i in 0..<l.count {
            if !epe(l: l[i], r: r[i]) { return false }
        }
        return true
    default: return false
    }
}

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
    //func sessionClassifierDidClassify(session: MKExerciseSession, classified: [MKExerciseWithLabels], sensorData: MKSensorData)

    ///
    /// Called when the session classification estimates that the setup movement for an exercise has been done
    ///
    /// - parameter session: the current snapshot of the session
    /// - parameter trigger: trigger that caused the classifier to "think" that there may be an exercise
    /// - returns: the updated session state
    ///
    func sessionClassifierDidSetupExercise(_ session: MKExerciseSession, trigger: MKSessionClassifierDelegateStartTrigger) -> MKExerciseSession.State?

    ///
    /// Called when the session classification estimates that an exercise has started
    ///
    /// - parameter session: the current snapshot of the session
    /// - parameter trigger: trigger that caused the classifier to "think" that there may be an exercise
    /// - returns: the updated session state
    ///
    func sessionClassifierDidStartExercise(_ session: MKExerciseSession, trigger: MKSessionClassifierDelegateStartTrigger) -> MKExerciseSession.State?

    ///
    /// Called when the session classification estimates the exercise that has ended
    ///
    /// - parameter session: the current snapshot of the session
    /// - parameter trigger: trigger that caused the classifier to "think" that there may no longer be an exercise
    /// - returns: the updated session state
    ///
    func sessionClassifierDidEndExercise(_ session: MKExerciseSession, trigger: MKSessionClassifierDelegateEndTrigger) -> MKExerciseSession.State?

    ///
    /// The session has ended
    ///
    /// - parameter session: the session that has just ended
    /// - parameter sensorData: the sensor data from the entire session
    ///
    func sessionClassifierDidEndSession(_ session: MKExerciseSession, sensorData: MKSensorData?)

    ///
    /// Called when the session starts
    ///
    /// - parameter session: the session that has just started
    ///
    func sessionClassifierDidStartSession(_ session: MKExerciseSession)
    
    ///
    /// Called every second after calculating the total reps of the whole exercise
    ///
    /// - parameter session: the session that has just started
    /// - parameter resp: the number of reps for the current exercise
    ///
    func repsCountFeed(_ session: MKExerciseSession, reps: Int, start: Date, end: Date)

}
