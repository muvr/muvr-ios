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
    typealias OnSelected = (MKExerciseDetail) -> Void
    private var onSelected: OnSelected!
    private var exerciseDetails: [MKExerciseDetail] = []
    
    ///
    /// The exercise details currently visible inside the scroll view
    ///
    var visibleExerciseDetails: [MKExerciseDetail] {
        return comingUpScrollView?.visibleSubviews.flatMap { ($0 as? MRAlternativeExerciseButton)?.exerciseDetail } ?? []
    }
    
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
        comingUpScrollView.contentSize = CGSize(width: buttonWidth * CGFloat(comingUpScrollView.subviews.count), height: comingUpScrollView.frame.height)
        for (index, button) in comingUpScrollView.subviews.enumerated() {
            button.frame = CGRect(x: CGFloat(index) * buttonWidth + buttonPadding, y: buttonPadding, width: buttonWidth - buttonPadding, height: buttonWidth - buttonPadding)
        }
    }
    
    ///
    /// Sets the exercises to be displayed, and the function to be called when an exercise is tapped
    /// - parameter exerciseDetails: the exercises details
    /// - parameter onSelected: the function to be called on selection
    ///
    func setExerciseDetails(_ exerciseDetails: [MKExerciseDetail], onSelected: OnSelected) {
        self.exerciseDetails = exerciseDetails
        self.onSelected = onSelected
        
        comingUpScrollView.subviews.forEach { $0.removeFromSuperview() }
        
        let buttonWidth = comingUpScrollView.frame.width / 3
        comingUpScrollView.contentSize = CGSize(width: buttonWidth * CGFloat(exerciseDetails.count), height: comingUpScrollView.frame.height)
        
        for exerciseDetail in exerciseDetails {
            let button = MRAlternativeExerciseButton(type: UIButtonType.system)
            button.lineWidth = 2
            button.setTitleColor(UIColor.darkText(), for: [])
            button.addTarget(self, action: #selector(MRSessionComingUpViewController.exerciseSelected(_:)), for: UIControlEvents.touchUpInside)
            button.exerciseDetail = exerciseDetail
            comingUpScrollView.addSubview(button)
        }
    }
    
    /// This needs to be public as a handler for the button tap event. Do not call.
    func exerciseSelected(_ sender: UIButton) {
        if let exercise = (sender as? MRAlternativeExerciseButton)?.exerciseDetail {
            onSelected(exercise)
        }
    }
}
