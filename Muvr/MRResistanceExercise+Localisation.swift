import Foundation

extension MRResistanceExercise {
    
    ///
    /// Gets the localised title for this exercise
    ///
    var localisedTitle: String {
        return MRApplicationState.exercises.find { $0.id == self.exercise }?.title ?? exercise
    }
    
}