import Foundation
import CoreData
import MuvrKit
import CoreLocation

class MRManagedExerciseSession: NSManagedObject, MKClassificationHintSource {
    private var currentClassificationHint: MKClassificationHint?
    private var exerciseIdCounts: [MKExerciseId : Int] = [:]
    /// The estimated exercises
    var estimated: [MKClassifiedExercise] = []
    /// The exercise plan
    var plan = MKExercisePlan<MKExerciseId>()
    /// The intended exercise type
    var intendedType: MKExerciseType?
    /// The weight predictor
    var weightPredictor: MKScalarPredictor!
    
    ///
    /// The exercise type inferred by taking the most frequently done exercise type in this session.
    /// If the user does what he or she intended, then ``intendedType`` == ``inferredType``, and both
    /// will be != nil.
    ///
    var inferredType: MKExerciseType? {
        var counter: [MKExerciseType : Int] = [:]
        for e in combinedExercises {
            let type = MKExerciseType(exerciseId: e.exerciseId)!
            if let count = counter[type] {
                counter[type] = count + 1
            } else {
                counter[type] = 1
            }
        }
        return counter.sort { l, r in return l.1 < r.1 } . map { $0.0 } . first
    }
    
    ///
    /// The complete list of exercises the user is likely to be doing
    ///
    var exercises: [MKIncompleteExercise] {
        let estimated = currentClassificationHint.map { _ in return self.estimatedExercises } ?? []
        let exercises = estimated + plannedExercises
        return exercises + allExercises(notIn: exercises)
    }
    
    ///
    /// Fills in the missing predictions for the given exercise
    /// - parameter exercise: the exercise
    /// - returns: the exercise with the predictions filled in
    ///
    func exerciseWithPredictions(exercise: MKIncompleteExercise) -> MKIncompleteExercise {
        let n = exerciseIdCounts[exercise.exerciseId] ?? 0
        let weight = weightPredictor.predictWeightForExerciseId(exercise.exerciseId, n: n)
        return exercise.copy(repetitions: nil, weight: weight, intensity: nil)
    }
    
    ///
    /// The list of exercises that the user is most likely to be doing next
    ///
    private var plannedExercises: [MKIncompleteExercise] {
        return plan.next.map {
            return MRIncompleteExercise(exerciseId: $0, repetitions: nil, intensity: nil, weight: nil, confidence: 1)
        }
    }
    
    ///
    /// The list of exercises that the user is most likely currently doing
    ///
    private var estimatedExercises: [MKIncompleteExercise] {
        return estimated.map { $0 as MKIncompleteExercise }
    }
    
    ///
    /// Returns all the exercises available in the current session and not present in the given list
    ///
    private func allExercises(notIn exercises: [MKIncompleteExercise]) -> [MKIncompleteExercise] {
        let allIds = MRAppDelegate.sharedDelegate().exerciseIds(inModel: exerciseModelId)
        let knownIds = exercises.map { $0.exerciseId }
        let otherIds = allIds.filter { !knownIds.contains($0) }
        return otherIds.map { MRIncompleteExercise(exerciseId: $0, repetitions: nil, intensity: nil, weight: nil, confidence: 0) }
    }
    
    // Implements the ``MKSessionClassifierHintSource.exercisingHints`` property
    var exercisingHints: [MKClassificationHint]? {
        get {
            var hints: [MKClassificationHint] = (labelledExercises.allObjects as! [MRManagedLabelledExercise]).map { le in
                return .ExplicitExercise(start: le.start.timeIntervalSinceDate(self.start), duration: le.duration, expectedExercises: [le])
            }
            if let currentClassificationHint = currentClassificationHint {
                hints.append(currentClassificationHint)
            }
            return hints
        }
    }
    
    ///
    /// Explicitly begins exercising. This call must be followed by ``addLabel`` at some point in the future.
    ///
    func beginExercising(exercise: MKIncompleteExercise) {
        currentClassificationHint =
            .ExplicitExercise(start: NSDate().timeIntervalSinceDate(start), duration: nil, expectedExercises: [exercise])
    }
    
    ///
    /// Explicitly ends exercising.
    ///
    func endExercising() {
        currentClassificationHint = nil
    }
    
    ///
    /// Adds the completed exercise to the plan. Do not forget to save the given ``managedObjectContext``, this
    /// method does not flush automatically.
    ///
    /// - parameter label: the completed exercise
    /// - parameter start: the exercise's start date
    /// - parameter duration: the exercise's duration
    /// - parameter managedObjectContext: the CD context into which the label is going to be inserted.
    ///
    func addLabel(label: MKIncompleteExercise, start: NSDate, duration: NSTimeInterval, inManagedObjectContext managedObjectContext: NSManagedObjectContext) {
        let l = MRManagedLabelledExercise.insertNewObject(into: self, inManagedObjectContext: managedObjectContext)
        
        l.start = start
        l.duration = duration
        l.exerciseId = label.exerciseId
        l.cdIntensity = label.intensity ?? 0
        l.cdRepetitions = label.repetitions ?? 0
        l.cdWeight = label.weight ?? 0

        // add to plan so we can get prediction for the next exercise
        plan.insert(label.exerciseId)
        
        // update internal counters for weight (and in the future) other predictions
        let n = exerciseIdCounts[label.exerciseId] ?? 0
        exerciseIdCounts[label.exerciseId] = n + 1
        
        // retrain for the given exercise
        let trainingSet: [Double] = (labelledExercises.allObjects as! [MRManagedLabelledExercise]).flatMap { existingLabel in
            if existingLabel.exerciseId == label.exerciseId {
                return existingLabel.weight
            }
            return nil
        }
        weightPredictor.trainPositional(trainingSet, forExerciseId: label.exerciseId)
        
        // reset classification hint
        currentClassificationHint = nil
    }
    
    ///
    /// Combined labelled and classified exercises for this entire session
    ///
    private var combinedExercises: [MKExercise] {
        let labelled: [(NSDate, MKExercise)] = (labelledExercises.allObjects as! [MRManagedLabelledExercise]).map { e in return (e.start, e as MKExercise) }
        let classified: [(NSDate, MKExercise)] = (classifiedExercises.allObjects as! [MRManagedClassifiedExercise]).map { e in return (e.start, e as MKExercise) }
        
        // filter out from the classified exercises those that fall into a label (with some tolerance)
        let classifiedOutsideLabels = classified.filter { (ceStart, _) in
            let timeTolerance: NSTimeInterval = 10
            return !labelled.contains { (leStart, _) in
                return leStart.timeIntervalSinceDate(ceStart) < timeTolerance
            }
        }
        
        // combine the labels with classified exercises
        let merged = (classifiedOutsideLabels + labelled).sort { l, r in return l.0.compare(r.0) == NSComparisonResult.OrderedAscending }
        
        // TODO: remove overlapping
        
        return merged.map { $0.1 }
    }
    
    ///
    /// Combined labelled and classified exercises grouped into sets
    ///
    var sets: [[MKExercise]] {
        get {
            var em: [MKExerciseId : [MKExercise]] = [:]
            combinedExercises.forEach { x in
                if let l = em[x.exerciseId] {
                    em[x.exerciseId] = l + [x]
                } else {
                    em[x.exerciseId] = [x]
                }
            }
            return em.values.sort { l, r in l.first!.exerciseId > r.first!.exerciseId }
        }
    }
        
}
