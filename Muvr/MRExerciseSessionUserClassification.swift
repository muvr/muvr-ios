import Foundation

struct MRExerciseSessionUserClassification {
    var classifiedSets: [MRResistanceExerciseSet]
    var otherSets: [MRResistanceExerciseSet]
    
    var simpleClassifiedSets: [MRResistanceExercise] {
        return simple(classifiedSets)
    }
    
    var simpleOtherSets: [MRResistanceExercise] {
        return simple(otherSets)
    }
    
    private func simple(set: [MRResistanceExerciseSet]) -> [MRResistanceExercise] {
        let simple = set.forall { $0.sets.count == 1 }
        if !simple { fatalError("set are not all simple") }
        return set.map { $0.sets[0] as! MRResistanceExercise }
    }

    init(properties: MRResistanceExerciseSessionProperties, result: [AnyObject]) {
        classifiedSets = (result as! [MRResistanceExerciseSet]).sorted( { x, y in return x.confidence() > y.confidence() });
        
        otherSets = [
            MRResistanceExercise(exercise: "arms/bicep-curl", andConfidence: 1),
            MRResistanceExercise(exercise: "arms/tricep-extension", andConfidence: 1),
        ].map { MRResistanceExerciseSet($0) }
    }
    
}