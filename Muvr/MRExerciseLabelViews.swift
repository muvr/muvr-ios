import Foundation
import MuvrKit

protocol MRExerciseLabelSetter {
    
    func increment() -> MKExerciseLabel
    
    func decrement() -> MKExerciseLabel
    
}

struct MRExerciseLabelViews {
    
    static func viewForExerciseDetail(exerciseDetail: MKExerciseDetail, label: MKExerciseLabel, frame: CGRect) -> UIView? {
        switch label {
        case .Intensity(let intensity):
            let view = MRBarsView(frame: frame)
            view.backgroundColor = UIColor.whiteColor()
            view.value = Int(intensity * 5)
            return view
        case .Repetitions(let repetitions):
            let view = MRRepetitionsView(frame: frame)
            view.backgroundColor = UIColor.whiteColor()
            view.value = repetitions
            return view
        case .Weight(let weight):
            let view = MRWeightView(frame: frame)
            view.value = weight
            view.backgroundColor = UIColor.whiteColor()
            return view
        }
    }
    
}
