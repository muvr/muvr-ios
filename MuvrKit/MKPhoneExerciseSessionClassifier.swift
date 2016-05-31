import Foundation

///
/// Provides a way to load a model given its identifier. Implementations should not only
/// load the underlying model, but should also consider other model & user-specific settings.
///
public protocol MKExerciseModelSource {

    ///
    /// Gets the exercise model for the given ``exerciseType``.
    ///
    /// - parameter exerciseType: the exercise type for which to load a model
    ///
    func exerciseModelForExerciseType(exerciseType: MKExerciseType) throws -> MKExerciseModel

    ///
    /// Gets the setup exercise model.
    ///
    func exerciseModelForExerciseSetup() throws -> MKExerciseModel

}

struct MKExerciseSessionDetail {
    /// The offset of the last classified exercises
    var classificationStart: NSTimeInterval = 0
}

///
/// Implementation of the two connectivity delegates that can classify the incoming data
///
public final class MKSessionClassifier : MKExerciseConnectivitySessionDelegate, MKSensorDataConnectivityDelegate {
    private let exerciseModelSource: MKExerciseModelSource

    /// all sessions
    private var sessions: [(MKExerciseSession, MKExerciseSessionDetail)] = []

    /// the classification result delegate
    private let delegate: MKSessionClassifierDelegate    // Remember to call the delegate methods on ``dispatch_get_main_queue()``

    /// the exercise vs. no-exercise classifier
    private let sensorDataSplitter: MKSensorDataSplitter

    /// the repetition estimator
    private let repetitionEstimator: MKRepetitionEstimator

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
            let es = MKExerciseSession(exerciseConnectivitySession: session)
            sessions[index] = (es, MKExerciseSessionDetail())
            delegate.sessionClassifierDidEndSession(es, sensorData: session.sensorData)
        }
    }

    public func exerciseConnectivitySessionDidStart(session session: MKExerciseConnectivitySession) {
        if sessionIndex(session) == nil {
            let exerciseSession = MKExerciseSession(exerciseConnectivitySession: session)
            sessions.append((exerciseSession, MKExerciseSessionDetail()))
            delegate.sessionClassifierDidStartSession(exerciseSession)
            if (session.end != nil) {
                delegate.sessionClassifierDidEndSession(exerciseSession, sensorData: session.sensorData)
            }
        }
    }

    /*
    private func classifySplits(splits: [MKSensorDataSplit], session: MKExerciseConnectivitySession) -> [MKExerciseWithLabels] {
        do {
            let exerciseModel = try exerciseModelSource.exerciseModelForExerciseType(session.exerciseType)
            let exerciseClassifier = try MKClassifier(model: exerciseModel)
            return try splits.flatMap { split in
                switch split {
                case .Automatic(let startOffset, let data):
                    if let (bestExercise, _) = (try exerciseClassifier.classify(block: data, maxResults: 10)).first {
                        let (repetitions, _) = try self.repetitionEstimator.estimate(data: data)
                        return (bestExercise.copy(offsetDelta: startOffset), [MKExerciseLabel.Repetitions(repetitions: repetitions)])
                    }

                case .Hinted(let startOffset, let data, _):
                    // TODO: improve the way in which we handle hint
                    if let (bestExercise, _) = (try exerciseClassifier.classify(block: data, maxResults: 10)).first {
                        let (repetitions, _) = try self.repetitionEstimator.estimate(data: data)
                        return (bestExercise.copy(offsetDelta: startOffset), [MKExerciseLabel.Repetitions(repetitions: repetitions)])
                    }
                }
                return nil
            }
        } catch {
            return []
        }
    }
    */

    public func sensorDataConnectivityDidReceiveSensorData(accumulated accumulated: MKSensorData, new: MKSensorData, session: MKExerciseConnectivitySession) {
        guard let index = sessionIndex(session) else { return } //TODO: fix this
        let et = sessions[index]
        var es = et.0
        let esd = et.1
        if (es.end == nil && session.end != nil) {
            // didn't know this session has ended - issue ``didEnd`` event
            delegate.sessionClassifierDidEndSession(es, sensorData: session.sensorData)
        }

        // split the accumulated data into areas of suspected exercise
        //let (completed, partial, newStart) = self.sensorDataSplitter.split(from: exerciseSession.classificationStart, data: accumulated)
        //exerciseSession.classificationStart = newStart
        //self.sessions[index] = exerciseSession

        // report the completely classified exercises
        //let classifiedCompleted = self.classifySplits(completed, session: session)
        //dispatch_async(dispatch_get_main_queue()) { self.delegate.sessionClassifierDidClassify(exerciseSession, classified: classifiedCompleted, sensorData: accumulated) }

        // report the estimated exercises
        //let classifiedPartial = self.classifySplits(partial, session: session)
        //dispatch_async(dispatch_get_main_queue()) { self.delegate.sessionClassifierDidEstimate(exerciseSession, estimated: classifiedPartial, motionDetected: new.motionDetected) }

        let detectedExercisesSetup = detectSetupMovement(accumulated, new: new, session: session, setupWindow: 5.0)
        if !detectedExercisesSetup.isEmpty {
            if let newState = delegate.sessionClassifierDidSetupExercise(es, trigger: .SetupDetected(exercises: detectedExercisesSetup)) {
                es.state = newState
                self.sessions[index] = (es, esd)
            }
        }

        switch es.state {
        case .SetupExercise(let exerciseId):
            //TODO: how will we handle the case of .SetupExercise?
            break

        case .Exercising:
            // first, check for no motion
            if !new.motionDetected, let newState = delegate.sessionClassifierDidEndExercise(es, trigger: .NoMotionDetected) {
                es.state = newState
                self.sessions[index] = (es, esd)
            }
            // next, if still "exercising", consider divergence
        case .NotExercising:
            // first, check for motion
            if new.motionDetected, let newState = delegate.sessionClassifierDidStartExercise(es, trigger: .MotionDetected) {
                es.state = newState
                self.sessions[index] = (es, esd)
            }
            // next, if the previous was insufficient, try setup classification
        }

        if session.last {
            // session completed: all data received
            sessions.removeAtIndex(index)
        }
    }

    private func detectSetupMovement(accumulated: MKSensorData, new: MKSensorData, session: MKExerciseConnectivitySession, setupWindow: NSTimeInterval) -> [MKExerciseProbability] {
        let now = NSDate()
        let accumlatedInterval = now.timeIntervalSinceDate(session.realStart!)
        if accumlatedInterval < setupWindow {
            return [MKExerciseProbability]()
        }
        let lastSlice: MKSensorData?
        do {
            lastSlice = try accumulated.slice(accumlatedInterval - setupWindow, duration: setupWindow)
        } catch {
            return [MKExerciseProbability]()
        }
        if !lastSlice!.motionDetected {
            return [MKExerciseProbability]()
        }
        let setupModel = try! exerciseModelSource.exerciseModelForExerciseSetup()
        let setupClassifier = try! MKClassifier(model: setupModel)
        let predictedExercises = try! setupClassifier.classify(block: lastSlice!, maxResults: 4)
        return predictedExercises.map({ (exercise, probability) -> MKExerciseProbability in
            return (exercise.id, probability)
        })
    }

    ///
    /// finds the session index in the active sessions
    ///
    private func sessionIndex(session: MKExerciseConnectivitySession) -> Int? {
        return sessions.indexOf { $0.0.id == session.id }
    }

}

import Accelerate

private extension MKSensorData {

    ///
    /// The variance of the samples contained in this sensor data
    ///
    var variance: [Float] {
        let values = UnsafeMutablePointer<Float>(self.samples)
        let rows = UInt(rowCount)

        if types.count != 1 { fatalError("variance not implemented for more than one sensor type.") }

        let type = types.first!
        return (0..<type.dimension).map { dim in
            var avg: Float = 0 // will hold the mean μ
            var dev = [Float](count: self.rowCount, repeatedValue: 0) // will hold (xi - μ)
            var variance: Float = 0
            let dimSamples = values.advancedBy(dim)

            vDSP_meanv(dimSamples, type.dimension, &avg, rows) // compute the mean
            avg *= -1
            vDSP_vsadd(dimSamples, type.dimension, &avg, &dev, 1, rows) // substract the mean
            vDSP_measqv(dev, 1, &variance, rows) // compute the variance

            return variance
        }
    }

    ///
    /// indicates if this sensor data contains any motion
    /// motion is detected when variance is above a given threshold
    ///
    var motionDetected: Bool {
        let v = variance.reduce(0.0) { return $0 + $1 }
        return v > 0.01
    }

}
