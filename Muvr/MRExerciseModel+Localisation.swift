import Foundation
import MuvrKit

extension MRExerciseModel {
    
    var exerciseTitles: [String] {
        let exs = MRDataModel.MRExerciseDataModel.get(NSLocale.currentLocale())
        return exercises.map { eid in return exs.find { $0.0 == eid }?.1 ?? eid }
    }
    
}
