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
    
    // TODO: Configurable
    /// The default repetitions
    private let defaultRepetitions = 10
    /// The default weight
    private let defaultWeight = 10.0
    /// The weight increment
    private let weightIncrement: Double = 1.0
    
    ///
    /// Sets the repetitions, weight and intensity from the given ``exercise``,
    /// calling the ``onUpdate`` function whenever the user changes the given
    /// values.
    ///
    /// - parameter exercise: the exercise whose values to be displayed
    /// - parameter onUpdate: a function that will be called on change of values
    ///
    func setExerciseDetail(exerciseDetail: MKExerciseDetail, onLabelsUpdated: OnLabelsUpdated) {
        self.onLabelsUpdated = onLabelsUpdated
        self.exerciseDetail = exerciseDetail
    }
        
    /// Calls the onUpdate with the appropriate values
    private func update() {
        
        onLabelsUpdated([])
    }
    
}
