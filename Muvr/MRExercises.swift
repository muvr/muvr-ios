import Foundation

struct MRExercises {
    var examples: [MRResistanceExercise]

    subscript(index: UInt8) -> MRResistanceExercise {
        return examples[Int(index)]
    }
    
}

