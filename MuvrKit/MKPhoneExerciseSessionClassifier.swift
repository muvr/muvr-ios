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
    
}

///
/// Implementation of the two connectivity delegates that can classify the incoming data
///
public final class MKSessionClassifier : MKExerciseConnectivitySessionDelegate, MKSensorDataConnectivityDelegate {
    private let exerciseModelSource: MKExerciseModelSource
    
    /// all sessions
    private(set) public var sessions: [MKExerciseSession] = []
    /// the current session
    public var session: MKExerciseSession? {
        return sessions.last
    }
    
    /// the classification result delegate
    private let delegate: MKSessionClassifierDelegate
    
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
    public init(exerciseModelSource: MKExerciseModelSource, delegate: MKSessionClassifierDelegate, unclassified: [MKExerciseConnectivitySession]) {
        self.exerciseModelSource = exerciseModelSource
        self.delegate = delegate
        unclassified.forEach(exerciseConnectivitySessionDidEnd)
    }
    
    public func exerciseConnectivitySessionDidEnd(session session: MKExerciseConnectivitySession) {
        // TODO: check that ids match
        guard let exerciseSession = sessions.last else { return }

        dispatch_async(dispatch_get_main_queue()) { self.delegate.sessionClassifierDidSummarise(exerciseSession) }
    }
    
    public func exerciseConnectivitySessionDidStart(session session: MKExerciseConnectivitySession) {
        let exerciseSession = MKExerciseSession()
        sessions.append(exerciseSession)
        dispatch_async(dispatch_get_main_queue()) { self.delegate.sessionClassifierDidStart(exerciseSession) }
    }
    
    public func sensorDataConnectivityDidReceiveSensorData(accumulated accumulated: MKSensorData, new: MKSensorData, session: MKExerciseConnectivitySession) {
        guard var exerciseSession = sessions.last else { return }
        
        let model = exerciseModelSource.getExerciseModel(id: session.exerciseModelId)
        let classifier = MKClassifier(model: model)
        
        dispatch_async(classificationQueue) {
            do {
                let classified = try classifier.classify(block: new, maxResults: 10)
                exerciseSession.classifiedExercises.appendContentsOf(classified)
                dispatch_async(dispatch_get_main_queue()) { self.delegate.sessionClassifierDidClassify(exerciseSession) }
            } catch {
                // TODO: ???
            }
        }
        
        sessions[sessions.count - 1] = exerciseSession
    }
    
}
