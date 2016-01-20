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
    /// The weight predictor
    var weightPredictor: MKScalarPredictor!
    /// The duration predictor
    var durationPredictor: MKScalarPredictor!
    /// The repetitions predictor
    var repetitionsPredictor: MKScalarPredictor!
    /// The intensity predictor
    var intensityPredictor: MKScalarPredictor!

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
        let n = exerciseIdCounts[id] ?? 0

        if let prediction = durationPredictor.predictScalarForExerciseId(exerciseDetail.0, n: n) {
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
        let defaultWeight: Double = properties.flatMap {
            switch $0 {
            case .WeightProgression(let minimum, let step, _): return minimum + step
            default: return nil
            }
        }.first ?? 10
        
        return exerciseType.labelDescriptors.reduce(([],[])) { labels, labelDescriptor in
            switch labelDescriptor {
            case .Repetitions:
                return repetitionsPredictor.predictScalarForExerciseId(id, n: n).map { value in
                    return (labels.0 + [.Repetitions(repetitions: Int(value))], labels.1)
                    } ?? (labels.0, labels.1 + [.Repetitions(repetitions: 10)])
            case .Weight:
                return weightPredictor.predictScalarForExerciseId(id, n: n).map { value in
                    return (labels.0 + [.Weight(weight: value)], labels.1)
                    } ?? (labels.0, labels.1 + [.Weight(weight: defaultWeight)])
            case .Intensity:
                return intensityPredictor.predictScalarForExerciseId(id, n: n).map { value in
                    return (labels.0 + [.Intensity(intensity: value)], labels.1)
                    } ?? (labels.0, labels.1 + [.Intensity(intensity: 0.5)])
            }
        }
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
        func extractLabelScalar(labelToScalar: MKExerciseLabel -> Double?)(row: ExerciseRow) -> Double? {
            for label in row.4 {
                if let value = labelToScalar(label) {
                    return value
                }
            }
            return nil
        }
        
        let offset = start.timeIntervalSinceDate(self.start)
        let (id, exerciseType, _) = exerciseDetail
        exerciseWithLabels.append((id, exerciseType, offset, duration, labels))
        
        // add to the plan
        plan.insert(id)
        
        // train the various predictors
        let historyForThisExercise = exerciseWithLabels.filter { e in return e.0 == id }
        
        let weights = historyForThisExercise.flatMap(extractLabelScalar { if case .Weight(let weight) = $0 { return weight } else { return nil } } )
        let intensities = historyForThisExercise.flatMap(extractLabelScalar { if case .Intensity(let intensity) = $0 { return intensity } else { return nil } } )
        let repetitions = historyForThisExercise.flatMap(extractLabelScalar { if case .Repetitions(let repetitions) = $0 { return Double(repetitions) } else { return nil } } )
        let durations = exerciseWithLabels.map { $0.3 }
        weightPredictor.trainPositional(weights, forExerciseId: id)
        durationPredictor.trainPositional(durations, forExerciseId: id)
        intensityPredictor.trainPositional(intensities, forExerciseId: id)
        repetitionsPredictor.trainPositional(repetitions, forExerciseId: id)
        
        // update counts
        exerciseIdCounts[id] = exerciseIdCounts[id].map { $0 + 1 } ?? 1
    }
    
}
