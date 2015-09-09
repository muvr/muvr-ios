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
        view.autoresizingMask = UIViewAutoresizing.FlexibleWidth | UIViewAutoresizing.FlexibleHeight
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
    
    override var frame: CGRect {
        didSet {
            if view != nil {
                view.frame = self.frame
                time.progressLineWidth = frame.height / 25
                repetitions.progressLineWidth = frame.height / 25
                topLabel.font = UIFont.systemFontOfSize(frame.height / 10, weight: UIFontWeightUltraLight)
            }
        }
    }

//    ///
//    /// Expands the current view to fill the entire width of the screen.
//    ///
//    func expand() {
//        if expanded { return }
//        expanded = true
//
//        let superFrame = superview?.frame ?? UIScreen.mainScreen().bounds
//        self.frame = CGRectMake(0, 0, superFrame.width, superFrame.width)
//        self.layoutIfNeeded()
//        
//    }
//    
//    ///
//    /// Collapses the current view 
//    ///
//    func collapse() {
//        if !expanded { return }
//        expanded = false
//
//        let superFrame = superview?.frame ?? UIScreen.mainScreen().bounds
//        self.frame = CGRectMake(0, 0, superFrame.width, superFrame.width / 2)
//        self.layoutIfNeeded()
//        
//        self.topLabel.font = UIFont.systemFontOfSize(self.frame.height / 10, weight: UIFontWeightUltraLight)
//        self.time.progressLineWidth = frame.height / 25
//        self.repetitions.progressLineWidth = frame.height / 25
//    }
    
}