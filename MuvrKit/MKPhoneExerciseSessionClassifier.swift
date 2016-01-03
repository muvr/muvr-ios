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
    private let delegate: MKSessionClassifierDelegate    // Remember to call the delegate methods on ``dispatch_get_main_queue()``
    
    /// the exercise vs. no-exercise classifier
    private let sensorDataSplitter: MKSensorDataSplitter

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
    /// - parameter sensorDataSplitter: the splitter
    /// - parameter delegate: the classifier delegate
    ///
    public init(exerciseModelSource: MKExerciseModelSource, sensorDataSplitter: MKSensorDataSplitter, delegate: MKSessionClassifierDelegate) {
        self.exerciseModelSource = exerciseModelSource
        self.delegate = delegate
        self.sensorDataSplitter = sensorDataSplitter
        repetitionEstimator = MKRepetitionEstimator()
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
    
    private func classifySplits(splits: [MKSensorDataSplit], session: MKExerciseConnectivitySession) -> [MKClassifiedExercise] {
        do {
            let exerciseModel = try exerciseModelSource.getExerciseModel(id: session.exerciseModelId)
            let exerciseClassifier = try MKClassifier(model: exerciseModel)
            return try splits.flatMap { split in
                switch split {
                case .Automatic(let startOffset, let data):
                    if let best = (try exerciseClassifier.classify(block: data, maxResults: 10)).first {
                        let (repetitions, _) = try self.repetitionEstimator.estimate(data: data)
                        return best.copy(offsetDelta: startOffset, repetitions: repetitions)
                    }
                    
                case .Hinted(let startOffset, let data, _):
                    // TODO: improve the way in which we handle hint
                    if let best = (try exerciseClassifier.classify(block: data, maxResults: 10)).first {
                        let (repetitions, _) = try self.repetitionEstimator.estimate(data: data)
                        return best.copy(offsetDelta: startOffset, repetitions: repetitions)
                    }
                }
                return nil
            }
        } catch {
            return []
        }
    }
    
    public func sensorDataConnectivityDidReceiveSensorData(accumulated accumulated: MKSensorData, new: MKSensorData, session: MKExerciseConnectivitySession) {
        guard let index = sessionIndex(session) else { return }
        var exerciseSession = MKExerciseSession(exerciseConnectivitySession: session)
        if (sessions[index].end == nil && session.end != nil) {
            // didn't know this session has ended - issue ``didEnd`` event
            dispatch_async(dispatch_get_main_queue()) { self.delegate.sessionClassifierDidEnd(exerciseSession, sensorData: session.sensorData) }
        }
        
        dispatch_async(classificationQueue) {
            // split the accumulated data into areas of suspected exercise
            let (completed, partial, newStart) = self.sensorDataSplitter.split(from: exerciseSession.classificationStart, data: accumulated)
            exerciseSession.classificationStart = newStart
            self.sessions[index] = exerciseSession

            // report the completely classified exercises
            let classifiedCompleted = self.classifySplits(completed, session: session)
            dispatch_async(dispatch_get_main_queue()) { self.delegate.sessionClassifierDidClassify(exerciseSession, classified: classifiedCompleted, sensorData: accumulated) }
            
            // report the estimated exercises
            let classifiedPartial = self.classifySplits(partial, session: session)
            dispatch_async(dispatch_get_main_queue()) { self.delegate.sessionClassifierDidEstimate(exerciseSession, estimated: classifiedPartial) }

            if session.last {
                // session completed: all data received
                self.sessions.removeAtIndex(index)
            }
        }
    }
    
    ///
    /// finds the session index in the active sessions
    ///
    private func sessionIndex(session: MKExerciseConnectivitySession) -> Int? {
        return sessions.indexOf { $0.id == session.id }
    }
    
}
