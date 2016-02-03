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
        
        func defaultWeight() -> Double {
            for property in properties {
                if case .WeightProgression(let minimum, let step, _) = property {
                    return minimum + step
                }
            }
            return 10
        }
        
        var labels: ([MKExerciseLabel], [MKExerciseLabel]) = exerciseType.labelDescriptors.reduce(([],[])) { labels, labelDescriptor in
            let (predictedLabels, missingLabels) = labels
            switch labelDescriptor {
            case .Repetitions:
                if let predictedRepetitions = repetitionsPredictor.predictScalarForExerciseId(id, n: n) {
                    return (predictedLabels + [.Repetitions(repetitions: Int(predictedRepetitions))], missingLabels)
                }
                return (predictedLabels, missingLabels + [.Repetitions(repetitions: 10)])
            case .Weight:
                if let predictedWeight = weightPredictor.predictScalarForExerciseId(id, n: n) {
                    return (predictedLabels + [.Weight(weight: predictedWeight)], missingLabels)
                }
                return (predictedLabels, missingLabels + [.Weight(weight: defaultWeight())])
            case .Intensity:
                if let predictedIntensity = intensityPredictor.predictScalarForExerciseId(id, n: n) {
                    return (predictedLabels + [.Intensity(intensity: predictedIntensity)], missingLabels)
                }
                return (predictedLabels, missingLabels + [.Intensity(intensity: 0.5)])
            }
        }
        
        // special case for intensity (as it depends on weight and reps)
        if let predictor = intensityPredictor as? MKLinearRegressionPredictor {
            let w: [Double] = labels.0.flatMap { if case .Weight(let w) = $0 { return w } else { return nil } }
            let r: [Int] = labels.0.flatMap { if case .Repetitions(let r) = $0 { return r } else { return nil } }
            var xs: [Double] = []
            if !w.isEmpty { xs.append(w[0]) }
            if !r.isEmpty { xs.append(Double(r[0])) }
            if !xs.isEmpty {
                let intensity = predictor.predictScalar(forExerciseId: id, n: n, values: xs)
                let index = labels.0.indexOf { if case .Intensity(_) = $0 { return true } else { return false } }
                if let intensity = intensity, let index = index  {
                    labels.0[index] = .Intensity(intensity: intensity)
                }
            }
        }
        
        return labels
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
        func extractLabelScalar(labelToScalar: MKExerciseLabel -> Double?) -> (ExerciseRow -> Double?) {
            return { row in
                for label in row.4 {
                    if let value = labelToScalar(label) {
                        return value
                    }
                }
                return nil
            }
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
        
        // Special case for intensity (as it depends on weight and reps)
        if let predictor = intensityPredictor as? MKLinearRegressionPredictor {
            var xs: [[Double]] = []
            if !weights.isEmpty { xs.append(weights) }
            if !repetitions.isEmpty { xs.append(repetitions) }
            if !xs.isEmpty {
                predictor.trainRegression(intensities, forExerciseId: id, dependentTrainingSet: xs)
            }
        }
        
        // update counts
        exerciseIdCounts[id] = exerciseIdCounts[id].map { $0 + 1 } ?? 1
    }
    
}
