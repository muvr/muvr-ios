import Foundation
import MBCircularProgressBar

class MRResistanceExerciseProgressView : UIView {
    @IBOutlet var view: UIView!
    @IBOutlet var topLabel: UILabel!
    @IBOutlet var bottomLabel: UILabel!
    @IBOutlet var time: MBCircularProgressBarView!
    @IBOutlet var repetitions: MBCircularProgressBarView!
    
    private var expanded: Bool = false
    private var text: String! = ""

    private func updateLabel() -> Void {
        let secs = Int(time.value)
        let reps = Int(repetitions.value)
        let sb = NSMutableString()
        if secs > 0 { sb.appendString("\(secs) s\n") }
        if reps > 0 { sb.appendString("\(reps) r") }
        topLabel.text = sb as String
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        NSBundle.mainBundle().loadNibNamed("MRResistanceExerciseProgressView", owner: self, options: nil)
        addSubview(view)
        topLabel.text = ""
        bottomLabel.text = ""
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
    
    ///
    ///
    ///
    func expand() {
        if expanded { return }
        expanded = true

        self.frame = CGRectMake(0, 0, self.superview!.frame.width, self.superview!.frame.width)
        self.layoutIfNeeded()
        
        time.progressLineWidth = frame.height / 25
        repetitions.progressLineWidth = frame.height / 25
        topLabel.font = UIFont.systemFontOfSize(frame.height / 10, weight: UIFontWeightUltraLight)
    }
    
    func collapse() {
        if !expanded { return }
        expanded = false

        let collapsed = CGRectMake(0, 0, self.frame.width, self.frame.width / 2)
        self.frame = collapsed
        self.layoutIfNeeded()
        
        self.topLabel.font = UIFont.systemFontOfSize(self.frame.height / 10, weight: UIFontWeightUltraLight)
        self.time.progressLineWidth = frame.height / 25
        self.repetitions.progressLineWidth = frame.height / 25
    }
        
}