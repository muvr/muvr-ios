import Foundation
import CoreData
import MuvrKit
import CoreLocation

class MRManagedExerciseSession: NSManagedObject, MKClassificationHintSource {
    private var currentClassificationHint: MKClassificationHint?
    /// The estimated exercises
    var estimated: [MKClassifiedExercise] = []
    /// The exercise plan
    var plan = MKExercisePlan<MKExerciseId>()
    /// The intended exercise type
    var intendedType: MKExerciseType?
    
    ///
    /// The exercise type inferred by taking the most frequently done exercise type in this session.
    /// If the user does what he or she intended, then ``intendedType`` == ``inferredType``, and both
    /// will be != nil.
    ///
    var inferredType: MKExerciseType? {
        var counter: [MKExerciseType : Int] = [:]
        for e in combinedExercises {
            let type = MKExerciseType.fromExerciseId(e.exerciseId)!
            if let count = counter[type] {
                counter[type] = count + 1
            } else {
                counter[type] = 1
            }
        }
        return counter.sort { l, r in return l.1 < r.1 } . map { $0.0 } . first
    }
    
    ///
    /// The list of exercises the user is likely to be doing
    ///
    var exercises: [MKIncompleteExercise] {
        if currentClassificationHint != nil {
            // we're exercising for sure
            return currentExercises
        } else {
            // we're not exercising
            return plannedExercises
        }
    }
        
    ///
    /// The list of exercises that the user is most likely to be doing next
    ///
    var plannedExercises: [MKIncompleteExercise] {
        let pes: [MKIncompleteExercise] = plan.next.map { exerciseId in
            return MRIncompleteExercise(exerciseId: exerciseId, repetitions: nil, intensity: nil, weight: nil, confidence: 1)
        }
        if !pes.isEmpty {
            return pes
        }
        return unplannedExercises
    }
    
    ///
    /// The other exercises that the user was probably not doing
    ///
    var unplannedExercises: [MKIncompleteExercise] {
        let modelExerciseIds = MRAppDelegate.sharedDelegate().exerciseIds(inModel: exerciseModelId)
        let planExerciseIds = plan.next
        return modelExerciseIds.filter { me in
            return !planExerciseIds.contains { pe in pe == me }
        }.sort { (l, r) in
            l < r
        }.map { exerciseId in
            return MRIncompleteExercise(exerciseId: exerciseId, repetitions: nil, intensity: nil, weight: nil, confidence: 0)
        }
    }
    
    ///
    /// The whole list of exercises starting with exercises that the user has most likely just finished doing
    ///
    private var nextExercises: [MKIncompleteExercise] {
        return plannedExercises + unplannedExercises
    }
    
    ///
    /// The list of exercises that the user is most likely currently doing
    ///
    private var currentExercises: [MKIncompleteExercise] {
        let planExercises = plan.next
        
        return (estimated.map { $0 as MKIncompleteExercise }) + planExercises.map { exerciseId in
            return MRIncompleteExercise(exerciseId: exerciseId, repetitions: nil, intensity: nil, weight: nil, confidence: 1)
        }
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
    /// Explicitly begins exercising. This call must be followed by ``addLabel`` at some point
    /// in the future.
    ///
    func beginExercising() {
        currentClassificationHint =
            .ExplicitExercise(start: NSDate().timeIntervalSinceDate(start), duration: nil, expectedExercises: currentExercises)
    }
    
    ///
    /// Explicitly ends exercising.
    ///
    func endExercise() {
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

        plan.insert(label.exerciseId)
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
