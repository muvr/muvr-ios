import Foundation

///
/// Provides a way to load a model given its identifier. Implementations should not only
/// load the underlying model, but should also consider other model & user-specific settings.
///
public protocol MKExerciseModelSource {
    
    ///
    /// Gets the exercise model for the given ``id``.
    ///
    /// - parameter id: the exercise model id to load
    ///
    func getExerciseModel(id id: MKExerciseModelId) throws -> MKExerciseModel
    
}

///
/// Implementation of the two connectivity delegates that can classify the incoming data
///
public final class MKSessionClassifier : MKExerciseConnectivitySessionDelegate, MKSensorDataConnectivityDelegate {
    private let exerciseModelSource: MKExerciseModelSource
    
    /// all sessions
    private(set) public var sessions: [MKExerciseSession] = []
    
    /// the classification result delegate
    public let delegate: MKSessionClassifierDelegate    // Remember to call the delegate methods on ``dispatch_get_main_queue()``

    /// the exercise vs. no-exercise classifier
    private let eneClassifier: MKClassifier

    /// the repetition estimator
    private let repetitionEstimator: MKRepetitionEstimator
    
    /// the queue for immediate classification, with high-priority QoS
    private let classificationQueue: dispatch_queue_t = dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0)
    /// the queue for summary & reclassification, if needed, with background QoS
    private let summaryQueue: dispatch_queue_t = dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0)

    ///
    /// Initializes this instance of the session classifier, supplying a list of so-far unclassified
    /// sessions. These will be classified with the device's best effort, keeping the as-it-happens
    /// classification as a priority
    ///
    /// - parameter exerciseModelSource: implementation of the ``MKExerciseModelSource`` protocol
    /// - parameter unclassified: the list of not-yet-classified connectivity sessions
    ///
    public init(exerciseModelSource: MKExerciseModelSource, delegate: MKSessionClassifierDelegate) {
        self.exerciseModelSource = exerciseModelSource
        self.delegate = delegate
        let slackingModel = try! exerciseModelSource.getExerciseModel(id: "slacking")
        eneClassifier = try! MKClassifier(model: slackingModel)
        repetitionEstimator = MKRepetitionEstimator()
    }
    
    private func classify(exerciseModelId exerciseModelId: MKExerciseModelId, sensorData: MKSensorData) -> [MKClassifiedExercise]? {
        do {
            let exerciseModel = try exerciseModelSource.getExerciseModel(id: exerciseModelId)
            let exerciseClassifier = try MKClassifier(model: exerciseModel)

            let results = try eneClassifier.classify(block: sensorData, maxResults: 2)
            NSLog("Exercise / no exercise \(results)")
            return try results.flatMap { result -> [MKClassifiedExercise] in
                if result.exerciseId == "E" && result.duration >= exerciseModel.minimumDuration {
                    // this is an exercise block - get the corresponding data section
                    let data = try sensorData.slice(result.offset, duration: result.duration)
                    // classify the exercises in this block
                    let exercises = try! exerciseClassifier.classify(block: data, maxResults: 10)
                    // adjust the offset with the offset from the original block
                    // the offset returned by the classifier is relative to the current exercise block
                    let (repetitions, _) = try self.repetitionEstimator.estimate(data: data)
                    return exercises.map(self.shiftOffset(result.offset)).map(self.updateRepetitions(repetitions))
                } else {
                    return []
                }
            }
        } catch let ex {
            NSLog("Failed to classify block: \(ex)")
            return []
        }
    }
    
    public func exerciseConnectivitySessionDidEnd(session session: MKExerciseConnectivitySession) {
        if let index = sessionIndex(session) {
            sessions[index] = MKExerciseSession(exerciseConnectivitySession: session)
            dispatch_async(dispatch_get_main_queue()) { self.delegate.sessionClassifierDidEnd(self.sessions[index], sensorData: session.sensorData) }
        }

// TODO: Re-think
//
//        dispatch_async(summaryQueue) {
//            if let exerciseSession = self.summarise(session: session) {
//                dispatch_async(dispatch_get_main_queue()) {
//                    self.delegate.sessionClassifierDidSummarise(exerciseSession, sensorData: session.sensorData)
//                }
//            }
//        }
    }
    
    public func exerciseConnectivitySessionDidStart(session session: MKExerciseConnectivitySession) {
        if sessionIndex(session) == nil {
            let exerciseSession = MKExerciseSession(exerciseConnectivitySession: session)
            sessions.append(exerciseSession)
            dispatch_async(dispatch_get_main_queue()) { self.delegate.sessionClassifierDidStart(exerciseSession) }
            if (session.end != nil) {
                dispatch_async(dispatch_get_main_queue()) { self.delegate.sessionClassifierDidEnd(exerciseSession, sensorData: session.sensorData) }
            }
        }
    }
    
    public func sensorDataConnectivityDidReceiveSensorData(accumulated accumulated: MKSensorData, new: MKSensorData, session: MKExerciseConnectivitySession) {
        guard let index = sessionIndex(session) else { return }
        let exerciseSession = MKExerciseSession(exerciseConnectivitySession: session)
        if (sessions[index].end == nil && session.end != nil) {
            // didn't know this session has ended - issue ``didEnd`` event
            dispatch_async(dispatch_get_main_queue()) { self.delegate.sessionClassifierDidEnd(exerciseSession, sensorData: session.sensorData) }
        }
        sessions[index] = exerciseSession
        
        // compute the exercise start date: new.start + exercise offset
        let shift = shiftOffset(new.start)
        
        dispatch_async(classificationQueue) {
            let classified = self.classify(exerciseModelId: session.exerciseModelId, sensorData: new) ?? []
            // always issue a ``didClassify`` event in order to save accumulated data
            dispatch_async(dispatch_get_main_queue()) { self.delegate.sessionClassifierDidClassify(exerciseSession, classified: classified.map(shift), sensorData: accumulated) }
        }
        
        if session.last {
            // session completed: all data received
            sessions.removeAtIndex(index)
        }
    }
    
    ///
    /// finds the session index in the active sessions
    ///
    private func sessionIndex(session: MKExerciseConnectivitySession) -> Int? {
        return sessions.indexOf { $0.id == session.id }
    }
    
    ///
    /// returns a function that shift the exercise's offset by the specified value
    ///
    private func shiftOffset(offset: MKTimestamp)(x: MKClassifiedExercise) -> MKClassifiedExercise {
        return MKClassifiedExercise(confidence: x.confidence, exerciseId: x.exerciseId, duration: x.duration, offset: x.offset + offset, repetitions: x.repetitions, intensity: x.intensity, weight: x.weight)
    }
    
    private func updateRepetitions(repetitions: UInt)(x: MKClassifiedExercise) -> MKClassifiedExercise {
        return MKClassifiedExercise(confidence: x.confidence, exerciseId: x.exerciseId, duration: x.duration, offset: x.offset, repetitions: repetitions, intensity: x.intensity, weight: x.weight)
    }
}
