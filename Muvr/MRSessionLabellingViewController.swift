import Foundation
import UIKit
import MuvrKit

///
/// Displays indicators that allow the user to select the repetitions, weight and intensity
/// To use, call ``setExercise`` supplying the predicted exercise, and a function that will
/// be called when the user changes the inputs.
///
class MRSessionLabellingViewController: UIViewController {
    @IBOutlet private weak var repetitionsView: MRRepetitionsView!
    @IBOutlet private weak var weightView: MRWeightView!
    @IBOutlet private weak var intensityView: MRBarsView!
    
    /// A function that carries the new values: (repetitions, weight, intensity)
    typealias OnLabelsUpdated = [MKExerciseLabel] -> Void
    /// The function that will be called whenever a value changes
    private var onLabelsUpdated: OnLabelsUpdated!
    
    private var exerciseDetail: MKExerciseDetail!
    
    ///
    /// Sets exercise detail and the labels for the users to verify.
    ///
    /// - parameter exerciseDetail: the exercise whose values to be displayed
    /// - parameter onUpdate: a function that will be called on change of values
    ///
    func setExerciseDetail(exerciseDetail: MKExerciseDetail, labels: [MKExerciseLabel], onLabelsUpdated: OnLabelsUpdated) {
        self.onLabelsUpdated = onLabelsUpdated
        self.exerciseDetail = exerciseDetail
    }
        
    /// Calls the onUpdate with the appropriate values
    private func update() {
        onLabelsUpdated([])
    }
    
}
