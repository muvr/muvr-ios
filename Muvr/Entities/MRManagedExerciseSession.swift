import Foundation
import CoreData
import MuvrKit

///
/// Represents a workout session and handles prediction of the next exercise set
///
class MRManagedExerciseSession: NSManagedObject {
    typealias ExerciseRow = (MKExercise.Id, MKExerciseType, TimeInterval, TimeInterval, [MKExerciseLabel])
    
    /// The number of exercise ids for next estimates
    private var exerciseIdCounts: [MKExercise.Id : Int] = [:]
    /// The exercise detail the user has explicitly started
    /// Viz ``setClassificationHint(_:labels:)`` and ``clearClassificationHint``
    private(set) internal var classificationHints: [MKClassificationHint] = []
    /// The accumulated exercise rows
    private(set) internal var exerciseWithLabels: [ExerciseRow] = []
    /// The last exercise done in this session (exercise detail, labels and duration, start time)
    private var lastExercise: (MKExerciseDetail, MKExerciseLabelsWithDuration, Date)? = nil

    /// The labels predictor
    var labelsPredictor: MKLabelsPredictor!
    
    ///
    /// The exercise details that are coming up, ordered by their score
    ///
    var exerciseDetailsComingUp: [MKExerciseDetail] {
        return MRAppDelegate.sharedDelegate().exerciseDetailsForExerciseIds(plan.next, favouringType: exerciseType)
    }
    
    func sessionClassifierDidSetupExercise(_ trigger: MKSessionClassifierDelegateStartTrigger) -> MKExerciseSession.State {
        if MRAppDelegate.sharedDelegate().deviceSteadyAndLevel {
            NotificationCenter.default.post(name: Notification.Name(rawValue: MRNotifications.SessionDidStartExercise.rawValue), object: objectID)
            return .setupExercise(exerciseId: "")
        }
        return .notExercising
    }

    ///
    /// Called on ``MKExerciseSessionClassifier.sessionClassifierDidStartExercise`` to process the transition
    /// and to decide whether to really move to the exercising state
    /// - parameter trigger: the trigger
    /// - returns: the new session state
    ///
    func sessionClassifierDidStartExercise(_ trigger: MKSessionClassifierDelegateStartTrigger) -> MKExerciseSession.State {
        if MRAppDelegate.sharedDelegate().deviceSteadyAndLevel {
            NotificationCenter.default.post(name: Notification.Name(rawValue: MRNotifications.SessionDidStartExercise.rawValue), object: objectID)
            return .exercising(exerciseId: "")
        }
        return .notExercising
    }

    ///
    /// Called on ``MKExerciseSessionClassifier.sessionClassifierDidEndExercise`` to process the transition
    /// and to decide whether to really move to the not exercising state
    /// - parameter trigger: the trigger
    /// - returns: the new session state
    ///
    func sessionClassifierDidEndExercise(_ trigger: MKSessionClassifierDelegateEndTrigger) -> MKExerciseSession.State {
        NotificationCenter.default.post(name: Notification.Name(rawValue: MRNotifications.SessionDidEndExercise.rawValue), object: objectID)
        return .notExercising
    }

    private func defaultDurationForExerciseDetail(_ exerciseDetail: MKExerciseDetail) -> TimeInterval {
        for property in exerciseDetail.properties {
            switch property {
            case .typicalDuration(let duration): return duration
            default: continue
            }
        }
        switch exerciseDetail.type {
        case .indoorsCardio: return 45 * 60
        case .resistanceTargeted: return 60
        case .resistanceWholeBody: return 60
        }
    }
    
    ///
    /// Predicts labels for the given ``exerciseDetail``.
    /// - parameter exerciseDetail: the ED
    /// - returns: Tuple containing the predicted labels (may be empty) in one-hand 
    ///            and the "not predicted" labels (with some sensible value) in the other
    ///
    func predictExerciseLabelsForExerciseDetail(_ exerciseDetail: MKExerciseDetail) -> (MKExerciseLabelsWithDuration, MKExerciseLabelsWithDuration) {
        let n = exerciseIdCounts[exerciseDetail.id] ?? 0
        
        func defaultWeight() -> Double {
            for property in exerciseDetail.properties {
                if case .weightProgression(let minimum, let step, _) = property {
                    return minimum + step
                }
            }
            return 10
        }
        
        let allPredictions = labelsPredictor.predictLabelsForExercise(exerciseDetail) ?? ([], nil, nil)
        
        let intensity = allPredictions.0.filter { $0.descriptor == .intensity }.first
        // remove intensity from the predicted values
        let predictions = allPredictions.0.filter { $0.descriptor != .intensity}
        
        let missing: [MKExerciseLabel] = exerciseDetail.labels.filter { desc in
            return !predictions.contains { $0.descriptor == desc}
        }.map {
            switch $0 {
            case .repetitions: return .repetitions(repetitions: 10)
            case .weight: return .weight(weight: defaultWeight())
            case .intensity: return intensity ?? .intensity(intensity: 0.5)
            }
        }
        var missingDuration: TimeInterval? = nil
        if allPredictions.1 == nil { missingDuration = defaultDurationForExerciseDetail(exerciseDetail) }
        
        var missingRest: TimeInterval? = nil
        if allPredictions.2 == nil { missingRest = 60 }
        
        return ((predictions, allPredictions.1, allPredictions.2) , (missing, missingDuration, missingRest))
    }
        
    ///
    /// Sets the exercise detail and predicted labels that the user is performing 
    /// (typically as a result of some user interaction). This serves as a hint to the
    /// classifier.
    /// - parameter exerciseDetail: the exercise detail
    /// - parameter labels: the predicted labels
    ///
    func setClassificationHint(_ exerciseDetail: MKExerciseDetail, labels: [MKExerciseLabel]) {
        correctLabelsForLastExercise()
        classificationHints = [.explicitExercise(start: Date().timeIntervalSince(start), duration: nil, expectedExercises: [(exerciseDetail, labels)])]
    }
    
    ///
    /// Compute the rest duration for the last exercise 
    /// and update the labels predictor
    ///
    private func correctLabelsForLastExercise() {
        if let (lastExercise, lastLabels, start) = lastExercise, let duration = lastLabels.1 {
            let endDate = Date(timeInterval: duration, since: start)
            let rest = Date().timeIntervalSince(endDate)
            labelsPredictor.correctLabelsForExercise(lastExercise, labels: (lastLabels.0, lastLabels.1, rest))
        }
        lastExercise = nil
    }
    
    ///
    /// Clears all classification hints
    ///
    func clearClassificationHints() {
        classificationHints = []
    }
    
    ///
    /// Adds the fully resolved ``exerciseDetail`` along with the ``labels`` to the session's exercises.
    /// The exercise spans from ``start``–``start + duration``; it will be inserted into the given ``managedObjectContext``.
    /// - parameter exerciseDetail: the exercise detail
    /// - parameter labels: the classified labels
    /// - parameter start: the start date
    /// - parameter duration: the duration
    ///
    func addExerciseDetail(_ exerciseDetail: MKExerciseDetail, labels: [MKExerciseLabel], start: Date, duration: TimeInterval) {
        let offset = start.timeIntervalSince(self.start as Date)
        exerciseWithLabels.append((exerciseDetail.id, exerciseDetail.type, offset, duration, labels))
        
        // add to the plan
        plan.insert(exerciseDetail.id)
        
        // save the exercise
        let labelsWithDuration: MKExerciseLabelsWithDuration = (labels, duration, nil) // don't no rest time yet
        lastExercise = (exerciseDetail, labelsWithDuration, start)
        labelsPredictor.correctLabelsForExercise(exerciseDetail, labels: labelsWithDuration)
        
        // update counts
        exerciseIdCounts[exerciseDetail.id] = exerciseIdCounts[exerciseDetail.id].map { $0 + 1 } ?? 1
    }
    
}
