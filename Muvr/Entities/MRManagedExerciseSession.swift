import Foundation
import CoreData
import MuvrKit

class MRManagedExerciseSession: NSManagedObject {
    /// The number of exercise ids for next estimates
    private var exerciseIdCounts: [MKExercise.Id : Int] = [:]
    /// The exercise detail the user has explicitly started
    /// Viz ``setClassificationHint(_:labels:)`` and ``clearClassificationHint``
    private(set) internal var classificationHints: [MKClassificationHint] = []
    
    /// The set of estimated exercises, used when the session is in real-time mode
    var estimated: [MKExerciseWithLabels] = []
    /// The weight predictor
    var weightPredictor: MKScalarPredictor!
    /// The weight predictor
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
    /// - returns: the predicted labels (may be empty)
    ///
    func predictExerciseLabelsForExerciseDetail(exerciseDetail: MKExerciseDetail) -> [MKExerciseLabel] {
        let (id, exerciseType, _) = exerciseDetail
        let n = exerciseIdCounts[id] ?? 0
        return exerciseType.labelDescriptors.flatMap {
            switch $0 {
            case .Repetitions: return repetitionsPredictor.predictScalarForExerciseId(id, n: n).map { .Repetitions(repetitions: Int($0)) }
            case .Weight: return weightPredictor.predictScalarForExerciseId(id, n: n).map { .Weight(weight: $0) }
            case .Intensity: return intensityPredictor.predictScalarForExerciseId(id, n: n).map { .Intensity(intensity: $0) }
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
    func addExerciseDetail(exerciseDetail: MKExerciseDetail, labels: [MKExerciseLabel], start: NSDate, duration: NSTimeInterval, inManagedObjectContext managedObjectContext: NSManagedObjectContext) {
        func scalarValueType(type: String, inExerciseId exerciseId: MKExercise.Id)(exercise: MRManagedExercise) -> Double? {
            if exercise.id == exerciseId {
                for label in exercise.scalarLabels.allObjects as! [MRManagedExerciseScalarLabel] {
                    if label.type == type {
                        return label.value.doubleValue
                    }
                }
            }
            return nil
        }
        
        
        let offset = start.timeIntervalSinceDate(self.start)
        let (id, exerciseType, _) = exerciseDetail
        MRManagedExercise.insertNewObjectIntoSession(self, id: id, exerciseType: exerciseType, labels: labels, offset: offset, duration: duration, inManagedObjectContext: managedObjectContext)
        
        // add to the plan
        plan.insert(id)
        
        // train the various predictors
        let sessionExercises = (exercises.allObjects as! [MRManagedExercise])
        let weights: [Double] = sessionExercises.flatMap(scalarValueType(MKExerciseLabelDescriptor.Weight.id, inExerciseId: id))
        let intensities: [Double] = sessionExercises.flatMap(scalarValueType(MKExerciseLabelDescriptor.Intensity.id, inExerciseId: id))
        let repetitions: [Double] = sessionExercises.flatMap(scalarValueType(MKExerciseLabelDescriptor.Repetitions.id, inExerciseId: id))
        let durations: [Double] = sessionExercises.flatMap { exercise in
            if exercise.id == id {
                return exercise.duration
            }
            return nil
        }
        weightPredictor.trainPositional(weights, forExerciseId: id)
        durationPredictor.trainPositional(durations, forExerciseId: id)
        intensityPredictor.trainPositional(intensities, forExerciseId: id)
        repetitionsPredictor.trainPositional(repetitions, forExerciseId: id)
        
        // update counts
        exerciseIdCounts[id] = exerciseIdCounts[id].map { $0 + 1 } ?? 0
    }
    
}
