import Foundation

extension MRMuscleGroup {
    
    var localisedExercises: [MRExercise] {
        let exs = MRDataModel.MRExerciseDataModel.get(NSLocale.currentLocale())
        return exs.filter { x in return self.exercises.exists { $0 == x.id } }
    }
    
}
