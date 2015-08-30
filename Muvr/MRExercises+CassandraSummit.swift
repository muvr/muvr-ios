import Foundation

extension MRExercises {
    
    static func cassandraSummit() -> MRExercises {
        return MRExercises(examples: [
                MRResistanceExercise(exercise: "Bicep curl", andConfidence: 1),
                MRResistanceExercise(exercise: "Chest fly", andConfidence: 1),
                MRResistanceExercise(exercise: "Shoulder press", andConfidence: 1)
            ])
    }
    
}