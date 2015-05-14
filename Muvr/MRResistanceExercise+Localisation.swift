import Foundation

extension MRResistanceExercise {
    
    var localisedTitle: String {
        return MRApplicationState.exercises.find { $0.id == self.exercise }?.title ?? exercise
    }
    
}