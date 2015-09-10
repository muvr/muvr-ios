import Foundation
import MBCircularProgressBar

class MRResistanceExerciseSessionProgressView : UIView {
    @IBOutlet var view: UIView!
    var intensities: MRResistanceExerciseIntensityView!

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        NSBundle.mainBundle().loadNibNamed("MRResistanceExerciseSessionProgressView", owner: self, options: nil)
        addSubview(view)
    }
    
    func setResistenceExercises(exercises: [MRClassifiedResistanceExercise]) -> Void {
        intensities.setResistenceExercises(exercises)
    }

    override var frame: CGRect {
        didSet {
            if view != nil {
                view.frame = self.frame
            }
        }
    }

}
