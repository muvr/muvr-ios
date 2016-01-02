import UIKit
import MuvrKit

class MRExerciseTableViewCell : UITableViewCell {
    static let nib: UINib = UINib(nibName: "MRExerciseTableViewCell", bundle: nil)
    static let cellReuseIdentifier: String = "ex"
    static let height = CGFloat(88)

    @IBOutlet weak var exerciseLabel: UILabel!
    @IBOutlet weak var repetitionsLabel: UILabel!
    @IBOutlet weak var intensityLabel: UILabel!
    @IBOutlet weak var weightLabel: UILabel!
    
    private(set) var exercise: MKExercise?
    
    func setExercise(exercise: MKExercise, lastExercise: MKExercise?) {
        exerciseLabel.text = exercise.exerciseId
        repetitionsLabel.text = exercise.repetitions.map { String($0) } ?? ""
        intensityLabel.text = exercise.intensity.map { String($0) } ?? ""
        weightLabel.text = exercise.weight.map { "\($0) kg" } ?? ""
        
        self.exercise = exercise
    }
    
}
