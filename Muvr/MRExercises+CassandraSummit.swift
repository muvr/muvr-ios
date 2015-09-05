import Foundation

extension MRExercises {
    
    static func cassandraSummit() -> MRExercises {
        return MRExercises(examples: [
                MRResistanceExercise(exercise: "Lateral rise", andConfidence: 1),
                MRResistanceExercise(exercise: "Triceps extension", andConfidence: 1),
                MRResistanceExercise(exercise: "Biceps curl", andConfidence: 1)
            ])
    }
    
}