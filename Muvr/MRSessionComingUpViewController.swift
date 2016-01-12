import Foundation
import UIKit
import MuvrKit

class MRSessionComingUpViewController: UIViewController {
    @IBOutlet weak var scrollView: UIScrollView!
    @IBAction func unwindToComingUp(unwindSegue: UIStoryboardSegue) { }
    
    private var onSelected: (MKIncompleteExercise -> Void)!
    
    func setExercises(exercises: [MKIncompleteExercise], onSelected: MKIncompleteExercise -> Void) {
        self.onSelected = onSelected
        let buttonWidth = scrollView.frame.width / 3
        
        for (index, exercise) in exercises.enumerate() {
            let button = MRAlternateExerciseButton()
            button.exercise = exercise
            button.frame = CGRectMake(CGFloat(index) * buttonWidth, 0, buttonWidth, buttonWidth)
            button.addTarget(self, action: "exerciseSelected:", forControlEvents: UIControlEvents.TouchUpInside)
            scrollView.addSubview(button)
        }
    }
    
    func exerciseSelected(sender: UIButton?) {
        if let exercise = (sender as? MRAlternateExerciseButton)?.exercise {
            onSelected(exercise)
        }
    }

}
