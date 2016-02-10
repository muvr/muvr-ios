import Foundation
import CoreData
import MuvrKit

class MRManagedExerciseSession: NSManagedObject {
    typealias ExerciseRow = (MKExercise.Id, MKExerciseType, NSTimeInterval, NSTimeInterval, [MKExerciseLabel])
    /// The number of exercise ids for next estimates
    private var exerciseIdCounts: [MKExercise.Id : Int] = [:]
    /// The exercise detail the user has explicitly started
    /// Viz ``setClassificationHint(_:labels:)`` and ``clearClassificationHint``
    private(set) internal var classificationHints: [MKClassificationHint] = []
    /// The accumulated exercise rows
    private(set) internal var exerciseWithLabels: [ExerciseRow] = []
    
    /// The set of estimated exercises, used when the session is in real-time mode
    var estimated: [MKExerciseWithLabels] = []
    /// The labels predictor
    var labelsPredictor: MKLabelsPredictor!

    /// The exercise plan
    var plan: MKExercisePlan<MKExercise.Id>!
    
    ///
    /// The exercise details that are coming up, ordered by their score
    ///
    var exerciseDetailsComingUp: [MKExerciseDetail] {
        return MRAppDelegate.sharedDelegate().exerciseDetailsForExerciseIds(plan.next, favouringType: exerciseType)
    }
    
    ///
    /// Predicts the duration for the given ``exerciseDetail``
    /// - parameter exerciseDetail: the exercise detail
    /// - returns: the expected duration
    ///
    func predictDurationForExerciseDetail(exerciseDetail: MKExerciseDetail) -> NSTimeInterval {
        let (id, exerciseType, properties) = exerciseDetail

        if let (_, prediction) = labelsPredictor.predictLabels(forExercise: id) {
            return prediction
        }
        
        for property in properties {
            switch property {
            case .TypicalDuration(let duration): return duration
            default: continue
            }
        }
        switch exerciseType {
        case .IndoorsCardio: return 45 * 60
        case .ResistanceTargeted: return 60
        case .ResistanceWholeBody: return 60
        }
    }
    
    ///
    /// Predicts the needed rest duration
    ///
    func predictRestDuration() -> NSTimeInterval {
        return 60
    }
    
    ///
    /// Predicts labels for the given ``exerciseDetail``.
    /// - parameter exerciseDetail: the ED
    /// - returns: Tuple containing the predicted labels (may be empty) in one-hand 
    ///            and the "not predicted" labels (with some sensible value) in the other
    ///
    func predictExerciseLabelsForExerciseDetail(exerciseDetail: MKExerciseDetail) -> ([MKExerciseLabel], [MKExerciseLabel]) {
        let (id, exerciseType, properties) = exerciseDetail
        let n = exerciseIdCounts[id] ?? 0
        
        func defaultWeight() -> Double {
            for property in properties {
                if case .WeightProgression(let minimum, let step, _) = property {
                    return minimum + step
                }
            }
            return 10
        }
        
        let predictions = labelsPredictor.predictLabels(forExercise: id)?.0 ?? []
        
        let missing: [MKExerciseLabel] = exerciseType.labelDescriptors.filter { desc in
            return !predictions.contains { $0.descriptor == desc}
        }.map {
            switch $0 {
            case .Repetitions: return .Repetitions(repetitions: 10)
            case .Weight: return .Weight(weight: defaultWeight())
            case .Intensity: return .Intensity(intensity: 0.5)
            }
        }
        
        return (predictions, missing)
    }
        
    ///
    /// Sets the exercise detail and predicted labels that the user is performing 
    /// (typically as a result of some user interaction). This serves as a hint to the
    /// classifier.
    /// - parameter exerciseDetail: the exercise detail
    /// - parameter labels: the predicted labels
    ///
    func setClassificationHint(exerciseDetail: MKExerciseDetail, labels: [MKExerciseLabel]) {
        classificationHints = [.ExplicitExercise(start: NSDate().timeIntervalSinceDate(start), duration: nil, expectedExercises: [(exerciseDetail, labels)])]
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
    /// - parameter managedObjectContext: the MOC
    ///
    func addExerciseDetail(exerciseDetail: MKExerciseDetail, labels: [MKExerciseLabel], start: NSDate, duration: NSTimeInterval) {
        let offset = start.timeIntervalSinceDate(self.start)
        let (id, exerciseType, _) = exerciseDetail
        exerciseWithLabels.append((id, exerciseType, offset, duration, labels))
        
        // add to the plan
        plan.insert(id)
        
        labelsPredictor.correctLabels(forExercise: id, labels: (labels, duration))
        
        // update counts
        exerciseIdCounts[id] = exerciseIdCounts[id].map { $0 + 1 } ?? 1
    }
    
}
