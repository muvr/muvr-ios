import Foundation
import UIKit
import MuvrKit

///
/// Displays a scroll view of exercises that are coming up in the exercise session.
/// To use, call the ``setExercises`` function, providing the list of exercises to
/// be displayed, and an action to be called when an exercise is selected.
///
class MRSessionComingUpViewController: UIViewController {
    @IBOutlet weak var comingUpScrollView: UIScrollView!
    typealias OnSelected = MKExerciseDetail -> Void
    private var onSelected: OnSelected!
    private var exerciseDetails: [MKExerciseDetail] = []
    
    ///
    /// set the accessibility identifiers
    ///
    override func viewDidLoad() {
        comingUpScrollView.accessibilityIdentifier = "Coming up exercises"
    }
    
    ///
    /// Compute the buttons' frames after scrollView layout
    ///
    override func viewDidLayoutSubviews() {
        let buttonWidth = comingUpScrollView.frame.width / 3
        let buttonPadding: CGFloat = 5
        comingUpScrollView.contentSize = CGSizeMake(buttonWidth * CGFloat(comingUpScrollView.subviews.count), comingUpScrollView.frame.height)
        for (index, button) in comingUpScrollView.subviews.enumerate() {
            button.frame = CGRectMake(CGFloat(index) * buttonWidth + buttonPadding, buttonPadding, buttonWidth - buttonPadding, buttonWidth - buttonPadding)
        }
    }
    
    ///
    /// Sets the exercises to be displayed, and the function to be called when an exercise is tapped
    /// - parameter exerciseDetails: the exercises details
    /// - parameter onSelected: the function to be called on selection
    ///
    func setExerciseDetails(exerciseDetails: [MKExerciseDetail], onSelected: OnSelected) {
        self.exerciseDetails = exerciseDetails
        self.onSelected = onSelected
        
        comingUpScrollView.subviews.forEach { $0.removeFromSuperview() }
        
        let buttonWidth = comingUpScrollView.frame.width / 3
        comingUpScrollView.contentSize = CGSizeMake(buttonWidth * CGFloat(exerciseDetails.count), comingUpScrollView.frame.height)
        
        for exerciseDetail in exerciseDetails {
            let button = MRAlternativeExerciseButton(type: UIButtonType.System)
            button.lineWidth = 2
            button.setTitleColor(UIColor.darkTextColor(), forState: .Normal)
            button.addTarget(self, action: #selector(MRSessionComingUpViewController.exerciseSelected(_:)), forControlEvents: UIControlEvents.TouchUpInside)
            button.exerciseDetail = exerciseDetail
            comingUpScrollView.addSubview(button)
        }
    }
    
    /// This needs to be public as a handler for the button tap event. Do not call.
    func exerciseSelected(sender: UIButton) {
        if let exercise = (sender as? MRAlternativeExerciseButton)?.exerciseDetail {
            onSelected(exercise)
        }
    }
}
