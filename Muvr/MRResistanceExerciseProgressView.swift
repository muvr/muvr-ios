import Foundation
import MBCircularProgressBar

class MRResistanceExerciseProgressView : UIView {
    @IBOutlet var view: UIView!
    @IBOutlet var topLabel: UILabel!
    @IBOutlet var bottomLabel: UILabel!
    @IBOutlet var time: MBCircularProgressBarView!
    @IBOutlet var repetitions: MBCircularProgressBarView!
    @IBOutlet var exercisingImage: UIImageView!
    
    private var text: String! = ""

    private func updateLabel() -> Void {
        let secs = Int(time.value)
        let reps = Int(repetitions.value)
        let sb = NSMutableString()
        if secs > 0 { sb.appendString("\(secs) s") }
        if reps > 0 {
            if sb.length > 0 { sb.appendString(" | ") }
            sb.appendString("\(reps) r")
        }
        topLabel.text = sb as String
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        NSBundle.mainBundle().loadNibNamed("MRResistanceExerciseProgressView", owner: self, options: nil)
        addSubview(view)
        topLabel.text = ""
        bottomLabel.text = ""
        exercisingImage.hidden = true
    }
    
    func setTime(value: Int, max: Int) -> Void {
        time.maxValue = CGFloat(max)
        time.value = CGFloat(value)
        updateLabel()
    }
    
    func setRepetitions(value: Int, max: Int) -> Void {
        repetitions.maxValue = CGFloat(max)
        repetitions.value = CGFloat(value)
        updateLabel()
    }
    
    func setText(text: String) -> Void {
        bottomLabel.text = text
    }
    
    var exercisingImageHidden: Bool {
        get {
            return exercisingImage.hidden
        }
        set {
            exercisingImage.hidden = newValue
        }
    }
        
}