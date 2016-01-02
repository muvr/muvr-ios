import Foundation
import CoreData
import MuvrKit

class MRManagedExerciseSession: NSManagedObject {
    private var plan = MKExercisePlan<MKExerciseId>()
    
    ///
    /// The list of exercises that the user has most likely just finished doing
    ///
    var suggestedExercises: [MKExercise] {
        let modelExercises = MRAppDelegate.sharedDelegate().exerciseIds(model: exerciseModelId)
        let planExercises = plan.nextExercises
        let notPlannedModelExercises = modelExercises.filter { me in
            return !planExercises.contains { pe in pe == me }
        }
        let a: [MKExercise] = planExercises.map { exerciseId in
            return MRExercise(exerciseId: exerciseId, duration: 30, repetitions: nil, intensity: nil, weight: nil, confidence: 1)
        }
        let b: [MKExercise] = notPlannedModelExercises.sort { (l, r) in l < r } . map { exerciseId in
            return MRExercise(exerciseId: exerciseId, duration: 30, repetitions: nil, intensity: nil, weight: nil, confidence: 0)
        }
        
        return a + b
    }
    
    ///
    /// The list of exercises that the user is most likely currently doing
    ///
    var currentExercises: [MKExercise] {
        let planExercises = plan.nextExercises
        
        // TODO: add classified-so-far exercise
        
        return planExercises.map { exerciseId in
            return MRExercise(exerciseId: exerciseId, duration: 30, repetitions: nil, intensity: nil, weight: nil, confidence: 1)
        }
    }
    
    ///
    /// Adds the completed exercise to the plan. Do not forget to save the given ``managedObjectContext``, this
    /// method does not flush automatically.
    ///
    /// - parameter label: the completed exercise
    /// - parameter start: the exercise's start date
    /// - parameter managedObjectContext: the CD context into which the label is going to be inserted.
    ///
    func addLabel(label: MKExercise, start: NSDate, inManagedObjectContext managedObjectContext: NSManagedObjectContext) {
        let l = MRManagedLabelledExercise.insertNewObject(into: self, inManagedObjectContext: managedObjectContext)
        
        l.start = start
        l.duration = label.duration
        l.exerciseId = label.exerciseId
        l.cdIntensity = label.intensity ?? 0
        l.cdRepetitions = label.repetitions ?? 0
        l.cdWeight = label.weight ?? 0

        plan.addExercise(label.exerciseId)
    }
    
    ///
    /// Combined labelled and classified exercises for this entire session
    ///
    var exercises: [MKExercise] {
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
            exercises.forEach { x in
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
