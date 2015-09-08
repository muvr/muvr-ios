import Foundation
import MBCircularProgressBar

class MRResistanceExerciseProgressView : UIView {
    @IBOutlet var view: UIView!
    @IBOutlet var topLabel: UILabel!
    @IBOutlet var bottomLabel: UILabel!
    @IBOutlet var time: MBCircularProgressBarView!
    @IBOutlet var repetitions: MBCircularProgressBarView!

    #if (arch(i386) || arch(x86_64)) && os(iOS)
    private let animationDuration = 2.0
    #else
    private let animationDuration = 0.5
    #endif
    
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
    
    func expand() {
        self.frame = self.superview!.frame
        self.layoutIfNeeded()
        
        time.progressLineWidth = 30
        repetitions.progressLineWidth = 30
        topLabel.font = UIFont.systemFontOfSize(40, weight: 0.3)
    }
    
    func collapse() {
        let collapsed = CGRectMake(0, 0, frame.width, frame.width / 2)
        self.frame = collapsed
        self.layoutIfNeeded()
        
        topLabel.font = UIFont.systemFontOfSize(16, weight: 0.3)
        time.progressLineWidth = 15
        repetitions.progressLineWidth = 15
    }
        
}