import UIKit
import MuvrKit

class MRExerciseSetTableViewCell : UITableViewCell {
    static let nib: UINib = UINib(nibName: "MRExerciseSetTableViewCell", bundle: nil)
    static let cellReuseIdentifier: String = "set"
    
    @IBOutlet weak var exerciseLabel: UILabel!
    @IBOutlet weak var setSizeLabel: UILabel!
    @IBOutlet weak var stacksView: MRStackView!
    
    func setSet(set: [MKExercise]) {
        assert(!set.isEmpty, "The set cannot be empty")
        set.forEach { x in assert(x.exerciseId == set.first!.exerciseId, "The set must be all same exercise ids") }
        
        exerciseLabel.text = set.first!.title
        setSizeLabel.text = String.localizedStringWithFormat(NSLocalizedString("%d set(s)", comment: "number of sets"), set.count)
        stacksView.empty()
        set.forEach { exercise in
            var color = UIColor.clearColor ()
            if let intensity = exercise.intensity {
                switch(intensity) {
                case 0..<0.34: color = UIColor.greenColor()
                case 0.34..<0.67: color = UIColor.orangeColor()
                default: color = UIColor.redColor()
                }
            }
            let reps = Int(exercise.repetitions ?? 0)
            self.stacksView.addStack(color: color, count: reps)
        }
    }
}


