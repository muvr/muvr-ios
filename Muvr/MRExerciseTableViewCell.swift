import UIKit
import MuvrKit

class MRExerciseTableViewCell : UITableViewCell {
    static let nib: UINib = UINib(nibName: "MRExerciseTableViewCell", bundle: nil)
    static let cellReuseIdentifier: String = "ex"

    @IBOutlet weak var exerciseLabel: UILabel!
    @IBOutlet weak var repetitionsLabel: UILabel!
    @IBOutlet weak var intensityLabel: UILabel!
    @IBOutlet weak var weightLabel: UILabel!
    
    func setClassifiedExercise(classifiedExercise: MKClassifiedExercise, lastClassifiedExercise: MKClassifiedExercise?) {
        exerciseLabel.text = classifiedExercise.exerciseId
        repetitionsLabel.text = classifiedExercise.repetitions.map { String($0) } ?? ""
        intensityLabel.text = classifiedExercise.intensity.map { String($0) } ?? ""
        weightLabel.text = classifiedExercise.weight.map { "\($0) kg" } ?? ""
    }
    
    func setPlannedExecise(plannedExercise: MKPlannedExercise, lastPlannedExercise: MKPlannedExercise?) {
        exerciseLabel.text = plannedExercise.exerciseId
        repetitionsLabel.text = plannedExercise.repetitions.map { String($0) } ?? ""
        intensityLabel.text = plannedExercise.intensity.map { String($0) } ?? ""
        weightLabel.text = plannedExercise.weight.map { "\($0) kg" } ?? ""
    }
    
}
