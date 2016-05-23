import Foundation
import CoreData
import MuvrKit

///
/// Represents a workout session and handles prediction of the next exercise set
///
class MRManagedExerciseSession: NSManagedObject {
    typealias ExerciseRow = (MKExercise.Id, MKExerciseType, NSTimeInterval, NSTimeInterval, [MKExerciseLabel])
    
    /// The number of exercise ids for next estimates
    private var exerciseIdCounts: [MKExercise.Id : Int] = [:]
    /// The exercise detail the user has explicitly started
    /// Viz ``setClassificationHint(_:labels:)`` and ``clearClassificationHint``
    private(set) internal var classificationHints: [MKClassificationHint] = []
    /// The accumulated exercise rows
    private(set) internal var exerciseWithLabels: [ExerciseRow] = []
    /// The last exercise done in this session (exercise detail, labels and duration, start time)
    private var lastExercise: (MKExerciseDetail, MKExerciseLabelsWithDuration, NSDate)? = nil

    /// The labels predictor
    var labelsPredictor: MKLabelsPredictor!
    
    ///
    /// The exercise details that are coming up, ordered by their score
    ///
    var exerciseDetailsComingUp: [MKExerciseDetail] {
        return MRAppDelegate.sharedDelegate().exerciseDetailsForExerciseIds(plan.next, favouringType: exerciseType)
    }
    
    func sessionClassifierDidSetupExercise(trigger: MKSessionClassifierDelegateStartTrigger) -> MKExerciseSession.State {
        if MRAppDelegate.sharedDelegate().deviceSteadyAndLevel {
            NSNotificationCenter.defaultCenter().postNotificationName(MRNotifications.SessionDidStartExercise.rawValue, object: objectID)
            return .SetupExercise(exerciseId: "")
        }
        return .NotExercising
    }

    ///
    /// Called on ``MKExerciseSessionClassifier.sessionClassifierDidStartExercise`` to process the transition
    /// and to decide whether to really move to the exercising state
    /// - parameter trigger: the trigger
    /// - returns: the new session state
    ///
    func sessionClassifierDidStartExercise(trigger: MKSessionClassifierDelegateStartTrigger) -> MKExerciseSession.State {
        if MRAppDelegate.sharedDelegate().deviceSteadyAndLevel {
            NSNotificationCenter.defaultCenter().postNotificationName(MRNotifications.SessionDidStartExercise.rawValue, object: objectID)
            return .Exercising(exerciseId: "")
        }
        return .NotExercising
    }

    ///
    /// Called on ``MKExerciseSessionClassifier.sessionClassifierDidEndExercise`` to process the transition
    /// and to decide whether to really move to the not exercising state
    /// - parameter trigger: the trigger
    /// - returns: the new session state
    ///
    func sessionClassifierDidEndExercise(trigger: MKSessionClassifierDelegateEndTrigger) -> MKExerciseSession.State {
        NSNotificationCenter.defaultCenter().postNotificationName(MRNotifications.SessionDidEndExercise.rawValue, object: objectID)
        return .NotExercising
    }

    private func defaultDurationForExerciseDetail(exerciseDetail: MKExerciseDetail) -> NSTimeInterval {
        for property in exerciseDetail.properties {
            switch property {
            case .TypicalDuration(let duration): return duration
            default: continue
            }
        }
        switch exerciseDetail.type {
        case .IndoorsCardio: return 45 * 60
        case .ResistanceTargeted: return 60
        case .ResistanceWholeBody: return 60
        }
    }
    
    ///
    /// Predicts labels for the given ``exerciseDetail``.
    /// - parameter exerciseDetail: the ED
    /// - returns: Tuple containing the predicted labels (may be empty) in one-hand 
    ///            and the "not predicted" labels (with some sensible value) in the other
    ///
    func predictExerciseLabelsForExerciseDetail(exerciseDetail: MKExerciseDetail) -> (MKExerciseLabelsWithDuration, MKExerciseLabelsWithDuration) {
        let n = exerciseIdCounts[exerciseDetail.id] ?? 0
        
        func defaultWeight() -> Double {
            for property in exerciseDetail.properties {
                if case .WeightProgression(let minimum, let step, _) = property {
                    return minimum + step
                }
            }
            return 10
        }
        
        let allPredictions = labelsPredictor.predictLabelsForExercise(exerciseDetail) ?? ([], nil, nil)
        
        let intensity = allPredictions.0.filter { $0.descriptor == .Intensity }.first
        // remove intensity from the predicted values
        let predictions = allPredictions.0.filter { $0.descriptor != .Intensity}
        
        let missing: [MKExerciseLabel] = exerciseDetail.labels.filter { desc in
            return !predictions.contains { $0.descriptor == desc}
        }.map {
            switch $0 {
            case .Repetitions: return .Repetitions(repetitions: 10)
            case .Weight: return .Weight(weight: defaultWeight())
            case .Intensity: return intensity ?? .Intensity(intensity: 0.5)
            }
        }
        var missingDuration: NSTimeInterval? = nil
        if allPredictions.1 == nil { missingDuration = defaultDurationForExerciseDetail(exerciseDetail) }
        
        var missingRest: NSTimeInterval? = nil
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
    func setClassificationHint(exerciseDetail: MKExerciseDetail, labels: [MKExerciseLabel]) {
        correctLabelsForLastExercise()
        classificationHints = [.ExplicitExercise(start: NSDate().timeIntervalSinceDate(start), duration: nil, expectedExercises: [(exerciseDetail, labels)])]
    }
    
    ///
    /// Compute the rest duration for the last exercise 
    /// and update the labels predictor
    ///
    private func correctLabelsForLastExercise() {
        if let (lastExercise, lastLabels, start) = lastExercise, let duration = lastLabels.1 {
            let endDate = NSDate(timeInterval: duration, sinceDate: start)
            let rest = NSDate().timeIntervalSinceDate(endDate)
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
    func addExerciseDetail(exerciseDetail: MKExerciseDetail, labels: [MKExerciseLabel], start: NSDate, duration: NSTimeInterval) {
        let offset = start.timeIntervalSinceDate(self.start)
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
