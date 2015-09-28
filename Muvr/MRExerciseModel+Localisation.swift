import Foundation
import MuvrKit

extension MKExerciseModel {
        
    var exerciseTitles: [String] {
        let exs = MRDataModel.MRExerciseDataModel.get(NSLocale.currentLocale())
        return exerciseIds.map { eid in return exs.find { $0.0 == eid }?.1 ?? eid }
    }
    
}
