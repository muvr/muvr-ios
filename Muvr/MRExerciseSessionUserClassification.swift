import Foundation

///
/// Implements the ordering and concatenating logic for the classification,
/// taking into account the different sources of data
///
struct MRExerciseSessionUserClassification {
    var plannedSet: MRResistanceExerciseSet?
    var classifiedSets: [MRResistanceExerciseSet]
    var otherSets: [MRResistanceExerciseSet]
    var data: NSData
    
    /// The combined simple view of the classified exercises
    var combinedSimpleSets: [MRResistanceExercise] {
        return simple(combinedSets)
    }
    
    /// the combined view of the classified sets
    var combinedSets: [MRResistanceExerciseSet] {
        if let x = plannedSet {
            return classifiedSets + [x] + otherSets
        }
        return classifiedSets + otherSets
    }
    
    /// The simple view of the classified exercises
    var simpleClassifiedSets: [MRResistanceExercise] {
        return simple(classifiedSets)
    }
    
    /// The simple view of the other exercises
    var simpleOtherSets: [MRResistanceExercise] {
        return simple(otherSets)
    }

    /// The simple view of the planned exercise
    var simplePlannedSet: MRResistanceExercise? {
        return plannedSet?.sets[0] as? MRResistanceExercise
    }
    
    private func simple(set: [MRResistanceExerciseSet]) -> [MRResistanceExercise] {
        let simple = set.forAll { $0.sets.count == 1 }
        if !simple { fatalError("set are not all simple") }
        return set.map { $0.sets[0] as! MRResistanceExercise }
    }

    init(properties: MRResistanceExerciseSessionProperties, data: NSData, result: [AnyObject], planned: [AnyObject]) {
        classifiedSets = (result as! [MRResistanceExerciseSet]).sorted( { x, y in return x.confidence() > y.confidence() });
        for planItem in (planned as! [MRExercisePlanItem]) {
            if let plannedExercise = planItem.resistanceExercise {
                plannedSet = MRResistanceExerciseSet(plannedExercise)
                break
            }
        }
        
        var exercises: [MRResistanceExercise] = []
        for mg in properties.muscleGroupIds {
            MRApplicationState.exercises.forEach { exercise in
                if exercise.isInMuscleGroupId(mg) { exercises.append(MRResistanceExercise(exercise: exercise.id, andConfidence: 1)) }
            }
        }
        
        otherSets = exercises.map { MRResistanceExerciseSet($0) }
        self.data = data
    }
    
}