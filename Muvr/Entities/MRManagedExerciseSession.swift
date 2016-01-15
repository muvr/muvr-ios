import Foundation
import CoreData
import MuvrKit
import CoreLocation

class MRManagedExerciseSession: NSManagedObject, MKClassificationHintSource {
    private var currentClassificationHint: MKClassificationHint?
    private var exerciseIdCounts: [MKExercise.Id : Int] = [:]
    /// The estimated exercises
    var estimated: [MKExerciseWithLabels] = []
    /// The exercise plan
    var plan = MKExercisePlan<MKExercise.Id>()
    /// The intended exercise type
    var intendedType: MKExerciseType?
    /// The weight predictor
    var weightPredictor: MKScalarPredictor!
    
    ///
    /// The complete list of exercises the user is likely to be doing
    ///
    var exercises: [MKExercise] {
        let estimated = currentClassificationHint.map { _ in return self.estimatedExercises } ?? []
        let exercises = estimated// + plannedExercises
        return exercises + allExercises(notIn: exercises)
    }
    
    ///
    /// Fills in the missing predictions for the given exercise
    /// - parameter exercise: the exercise
    /// - returns: the exercise with the predictions filled in
    ///
    func predictLabels(exerciseId: MKExercise.Id) -> [MKExerciseLabel] {
        let n = exerciseIdCounts[exerciseId] ?? 0
        if let weight = weightPredictor.predictScalarForExerciseId(exerciseId, n: n) {
            return [.Weight(weight: weight)]
        }
        return []
    }
    
    ///
    /// The list of exercises that the user is most likely to be doing next
    ///
    private var plannedExercises: [MKExercise.Id] {
        return plan.next
    }
    
    ///
    /// The list of exercises that the user is most likely currently doing
    ///
    private var estimatedExercises: [MKExerciseWithLabels] {
        return estimated
    }
    
    ///
    /// Returns all the exercises available in the current session and not present in the given list
    ///
    private func allExercises(notIn exercises: [MKExercise.Id]) -> [MKExercise.Id] {
        let allIds = MRAppDelegate.sharedDelegate().exerciseIds(inModel: exerciseModelId)
        let knownIds = exercises
        let otherIds = allIds.filter { !knownIds.contains($0) }
        var allExerciseIds = otherIds
        allExerciseIds.sortInPlace { l, r in
            let lType = MKExerciseType(exerciseId: l)
            let rType = MKExerciseType(exerciseId: r)
            switch (lType == self.intendedType, rType == self.intendedType) {
            case (true, true): return l.title < r.title
            case (true, false): return true
            case (false, true): return false
            case (false, false): return l.title < r.title
            }
        }
        return allExerciseIds
    }
    
    // Implements the ``MKSessionClassifierHintSource.exercisingHints`` property
    var exercisingHints: [MKClassificationHint]? {
        get {
            return nil
//            var hints: [MKClassificationHint] = (labelledExercises.allObjects as! [MRManagedLabelledExercise]).map { le in
//                return .ExplicitExercise(start: le.start.timeIntervalSinceDate(self.start), duration: le.duration, expectedExercises: [le])
//            }
//            if let currentClassificationHint = currentClassificationHint {
//                hints.append(currentClassificationHint)
//            }
//            return hints
        }
    }
    
    ///
    /// Explicitly begins exercising. This call must be followed by ``addLabel`` at some point in the future.
    ///
    func beginExercising(exercise: MKExerciseWithLabels) {
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
    func adExerciseWithLabels(exerciseWithLabels: MKExerciseWithLabels, start: NSDate, duration: NSTimeInterval, inManagedObjectContext managedObjectContext: NSManagedObjectContext) {
        let (exercise, labels) = exerciseWithLabels

        // add to plan so we can get prediction for the next exercise
        plan.insert(exercise.id)
        
        // update internal counters for weight (and in the future) other predictions
        let n = exerciseIdCounts[exercise.id] ?? 0
        exerciseIdCounts[exercise.id] = n + 1
        
        // retrain for the given exercise
//        let trainingSet: [Double] = (labelledExercises.allObjects as! [MRManagedLabelledExercise]).flatMap { existingLabel in
//            if existingLabel.exerciseId == label.exerciseId {
//                return existingLabel.weight
//            }
//            return nil
//        }
//        weightPredictor.trainPositional(trainingSet, forExerciseId: label.exerciseId)

        // reset classification hint
        currentClassificationHint = nil
    }
    
    ///
    /// Combined labelled and classified exercises grouped into sets
    ///
    var sets: [[MKExercise]] {
        get {
            return []
//            var em: [MKExercise.Id : [MKExercise]] = [:]
//            combinedExercises.forEach { x in
//                if let l = em[x.exerciseId] {
//                    em[x.exerciseId] = l + [x]
//                } else {
//                    em[x.exerciseId] = [x]
//                }
//            }
//            return em.values.sort { l, r in l.first!.exerciseId > r.first!.exerciseId }
        }
    }
        
}
