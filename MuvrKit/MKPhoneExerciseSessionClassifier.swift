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
    func getExerciseModel(id id: MKExerciseModelId) -> MKExerciseModel
    
    ///
    /// Gets the exercise/slacking model
    ///
    func getSlackingModel() -> MKExerciseModel
    
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
    }
    
    private func classify(exerciseModelId exerciseModelId: MKExerciseModelId, sensorData: MKSensorData) -> [MKClassifiedExercise]? {
        do {
            let slackingModel = exerciseModelSource.getSlackingModel()
            let slackingClassifier = try MKClassifier(model: slackingModel)
            let exerciseModel = exerciseModelSource.getExerciseModel(id: exerciseModelId)
            let exerciseClassifier = try MKClassifier(model: exerciseModel)

            let results = try slackingClassifier.classify(block: sensorData, maxResults: 2)
            return results.flatMap { result -> [MKClassifiedExercise] in
                if result.exerciseId == "E" {
                    let data = try! sensorData.splitAt(result.offset, duration: result.duration)
                    return try! exerciseClassifier.classify(block: data, maxResults: 10)
                } else {
                    return []
                }
            }
        } catch let ex {
            NSLog("Failed to classify block: \(ex)")
            return nil
        }
    }
    
    public func exerciseConnectivitySessionDidEnd(session session: MKExerciseConnectivitySession) {
        // TODO: Improve me? The ``session`` is the whole thing, presumably, we can just add instead of needing the last element
        if sessions.count == 0 { return }
        
        dispatch_async(dispatch_get_main_queue()) { self.delegate.sessionClassifierDidEnd(self.sessions.last!, sensorData: session.sensorData) }

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
        let exerciseSession = MKExerciseSession(exerciseConnectivitySession: session)
        sessions.append(exerciseSession)
        dispatch_async(dispatch_get_main_queue()) { self.delegate.sessionClassifierDidStart(exerciseSession) }
    }
    
    public func sensorDataConnectivityDidReceiveSensorData(accumulated accumulated: MKSensorData, new: MKSensorData, session: MKExerciseConnectivitySession) {
        guard let exerciseSession = sessions.last else { return }
        
        func shiftOffset(x: MKClassifiedExercise) -> MKClassifiedExercise {
            // accumulated contains all sensor data (including new)
            let offset = x.offset + accumulated.duration - new.duration
            return MKClassifiedExercise(confidence: x.confidence, exerciseId: x.exerciseId, duration: x.duration, offset: offset, repetitions: x.repetitions, intensity: x.intensity, weight: x.weight)
        }
        
        dispatch_async(classificationQueue) {
            if let classified = self.classify(exerciseModelId: session.exerciseModelId, sensorData: new) {
                dispatch_async(dispatch_get_main_queue()) { self.delegate.sessionClassifierDidClassify(exerciseSession, classified: classified.map(shiftOffset), sensorData: accumulated) }
            }
        }
    }
    
}
