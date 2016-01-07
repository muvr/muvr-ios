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
        let formatter = MRExerciseIdFormatter(style: .Short)
        exerciseLabel.text = formatter.format(exercise.exerciseId).localizedCapitalizedString
        
        let nbFormatter = NSNumberFormatter()
        repetitionsLabel.text = exercise.repetitions.flatMap { reps in nbFormatter.stringFromNumber(NSNumber(int: reps)) } ?? ""
        intensityLabel.text = exercise.intensity.flatMap { intensity in
            let percent = Int32(round(intensity * 100))
            return nbFormatter.stringFromNumber(NSNumber(int: percent))
        } ?? ""
        weightLabel.text = exercise.weight.map { kg in
            let formatter = NSMassFormatter()
            return formatter.stringFromKilograms(kg)
        } ?? ""
        
        self.exercise = exercise
    }
    
}
