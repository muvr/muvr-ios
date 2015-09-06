import Foundation

extension MRResistanceExercise {
    
    ///
    /// Gets the localised title for this exercise
    ///
    var title: String {
        let exs = MRDataModel.MRExerciseDataModel.get(NSLocale.currentLocale())
        return exs.find { $0.0 == self.id }?.1 ?? id
    }
    
}