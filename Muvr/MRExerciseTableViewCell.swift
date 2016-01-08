import UIKit
import MuvrKit

///
/// Implements the single exercise cell 
///
class MRExerciseTableViewCell : UITableViewCell {
    static let nib: UINib = UINib(nibName: "MRExerciseTableViewCell", bundle: nil)
    static let cellReuseIdentifier: String = "ex"
    static let height = CGFloat(88)

    @IBOutlet weak var exerciseLabel: UILabel!
    @IBOutlet weak var repetitionsLabel: UILabel!
    @IBOutlet weak var intensityLabel: UILabel!
    @IBOutlet weak var weightLabel: UILabel!
    
    /// Gets the exercise the cell is displaying
    private(set) var exercise: MKIncompleteExercise?
    
    ///
    /// Sets the ``exercise`` to be displayed, optionally comparing it to the last exercise of the same id
    /// - parameter exercise: the exercise to be displayed
    /// - parameter lastExercise: the last completed exercise of the same id
    ///
    func setExercise(exercise: MKIncompleteExercise, lastExercise: MKExercise?) {
        exerciseLabel.text = exercise.title
        
        repetitionsLabel.text = exercise.repetitions.map { reps in
            return String.localizedStringWithFormat(NSLocalizedString("%d rep(s)", comment: "number of reps"), reps)
        } ?? ""
        intensityLabel.text = exercise.intensity.map { intensity in
            let percent = Int32(round(intensity * 100))
            return String.localizedStringWithFormat(NSLocalizedString("%d %%", comment: "intensity percentage"), percent)
        } ?? ""
        weightLabel.text = exercise.weight.map { kg in
            let formatter = NSMassFormatter()
            return formatter.stringFromKilograms(kg)
        } ?? ""
        
        self.exercise = exercise
    }
    
}
