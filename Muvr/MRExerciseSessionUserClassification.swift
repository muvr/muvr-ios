import Foundation

struct MRExerciseSessionUserClassification {
    var plannedSet: MRResistanceExerciseSet?
    var classifiedSets: [MRResistanceExerciseSet]
    var otherSets: [MRResistanceExerciseSet]
    
    var simpleClassifiedSets: [MRResistanceExercise] {
        return simple(classifiedSets)
    }
    
    var simpleOtherSets: [MRResistanceExercise] {
        return simple(otherSets)
    }

    var simplePlannedSet: MRResistanceExercise? {
        return plannedSet?.sets[0] as? MRResistanceExercise
    }
    
    private func simple(set: [MRResistanceExerciseSet]) -> [MRResistanceExercise] {
        let simple = set.forAll { $0.sets.count == 1 }
        if !simple { fatalError("set are not all simple") }
        return set.map { $0.sets[0] as! MRResistanceExercise }
    }

    init(properties: MRResistanceExerciseSessionProperties, result: [AnyObject], planned: [AnyObject]) {
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
    }
    
}