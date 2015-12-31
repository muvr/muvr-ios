import UIKit
import MBCircularProgressBar

class MRTimedView : UIView {
    enum CountingStyle {
        case Elapsed
        case Remaining
    }
    
    @IBOutlet weak var button: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var circularProgressBarView: MBCircularProgressBarView!
    
    typealias Event = MRTimedView -> Void
    private var duration: NSTimeInterval?
    private var start: NSDate?
    private var timer: NSTimer?
    private var onTimerElapsed: Event?
    
    var onTouchUpInside: Event?
    var countingStyle: CountingStyle = CountingStyle.Remaining
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        let x = NSBundle.mainBundle().loadNibNamed("MRTimedView", owner: self, options: nil).first! as! UIView
        addSubview(x)
    }
    
    func setColourScheme(colourScheme: MRColourScheme) {
        button.tintColor = colourScheme.tint
        button.backgroundColor = colourScheme.background
        circularProgressBarView.progressColor = colourScheme.light
        circularProgressBarView.progressStrokeColor = colourScheme.light
    }
    
    func start(duration: NSTimeInterval, onTimerElapsed: Event? = nil) {
        self.timer?.invalidate()
        self.duration = duration
        self.start = NSDate()
        self.onTimerElapsed = onTimerElapsed
        self.timer = NSTimer.scheduledTimerWithTimeInterval(0.5, target: self, selector: "onTimerTick", userInfo: nil, repeats: true)
    }
    
    func stop() {
        self.timer?.invalidate()
    }
    
    @IBAction func buttonTouched() {
        if let onTouchUpInside = onTouchUpInside {
            onTouchUpInside(self)
        }
    }
    
    func onTimerTick() {
        guard let start = start, duration = duration, onTimerElapsed = onTimerElapsed else { return }
        let elapsed = -start.timeIntervalSinceNow
        if elapsed > duration {
            onTimerElapsed(self)
        }

        var timeToDisplay: NSTimeInterval = 0
        switch countingStyle {
        case .Elapsed: timeToDisplay = elapsed
        case .Remaining: timeToDisplay = duration - elapsed
        }
        
        circularProgressBarView.value = CGFloat(timeToDisplay)
        button.setTitle(String(Int(timeToDisplay)), forState: UIControlState.Normal)
    }
    
    
}
