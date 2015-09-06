import Foundation

extension MRExerciseModel {
    
    var localisedExercises: [MRResistanceExercise] {
        let exs = MRDataModel.MRResistanceExerciseDataModel.get(NSLocale.currentLocale())
        return exs.filter { x in return self.exercises.exists { $0 == x.id } }
    }
    
}
