import UIKit
import MBCircularProgressBar

///
/// A view that contains a progress bar and a button that can count down or up to
/// some specified duration.
///
class MRTimedView : UIView {
    ///
    /// Display style: count down or count up
    ///
    enum CountingStyle {
        /// Display elapsed
        case Elapsed
        /// Display remaining
        case Remaining
    }
    
    @IBOutlet weak var button: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var circularProgressBarView: MBCircularProgressBarView!
    
    typealias Event = MRTimedView -> Void
    typealias TextTransform = NSTimeInterval -> String
    
    private var duration: NSTimeInterval?
    private var start: NSDate?
    private var timer: NSTimer?
    private var onTimerElapsed: Event?
    
    /// when ``true``, button touch resets the counter and stops the timer
    var buttonTouchResets: Bool = true
    /// the event called on button touch
    var buttonTouched: Event?
    /// the counting style
    var countingStyle: CountingStyle = CountingStyle.Remaining
    /// the text transformation
    var textTransform: TextTransform = MRTimedView.simple
    
    ///
    /// A basic text transform that converts the ``time`` to its representation in seconds
    /// - parameter time: the time to convert
    /// - returns: the time rounded to seconds as string
    ///
    static func simple(time: NSTimeInterval) -> String {
        return String(Int(time))
    }
    
    ///
    /// Initializes this view from a given decoder
    ///
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        // TODO: is this right / optimal way to do this?
        let x = NSBundle.mainBundle().loadNibNamed("MRTimedView", owner: self, options: nil).first! as! UIView
        addSubview(x)
    }
    
    ///
    /// Sets the colour scheme
    /// - parameter colourScheme: the new colour scheme
    ///
    func setColourScheme(colourScheme: MRColourScheme) {
        button.tintColor = colourScheme.tint
        button.backgroundColor = colourScheme.background
        titleLabel.textColor = colourScheme.tint
        circularProgressBarView.progressColor = colourScheme.light
        circularProgressBarView.progressStrokeColor = colourScheme.background
        circularProgressBarView.emptyLineColor = colourScheme.darker.background
    }
    
    ///
    /// Starts a timer for the given ``duration``, calling ``onTimerElapsed`` at the end
    /// - parameter duration: the duration
    /// - parameter onTimerElapsed: function to be called when the timer is up
    ///
    func start(duration: NSTimeInterval, onTimerElapsed: Event? = nil) {
        self.timer?.invalidate()
        self.duration = duration
        self.start = NSDate()
        self.circularProgressBarView.maxValue = CGFloat(duration)
        self.onTimerElapsed = onTimerElapsed
        self.timer = NSTimer.scheduledTimerWithTimeInterval(0.5, target: self, selector: "onTimerTick", userInfo: nil, repeats: true)
    }
    
    ///
    /// Resets the counter and stops the timer
    ///
    func stop() {
        self.circularProgressBarView.value = 0
        self.timer?.invalidate()
    }
    
    @IBAction func onButtonTouched() {
        if let buttonTouched = buttonTouched {
            buttonTouched(self)
        }
        if buttonTouchResets { stop() }
    }
    
    ///
    /// Intended to be called on timer tick; do not call explicitly
    ///
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
        button.setTitle(textTransform(timeToDisplay), forState: UIControlState.Normal)
    }
    
    
}
