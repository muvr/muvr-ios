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
    private var timerChanged: Bool = false
    
    /// when ``true``, button touch resets the counter and stops the timer
    var buttonTouchResets: Bool = true
    /// when ``true``, when the timer elapses, the counter and timer stop
    var elapsedResets: Bool = false
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
        circularProgressBarView.hidden = true
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        button.layer.cornerRadius = (frame.height - 8) / 2
        let f = button.titleLabel!.font
        button.titleLabel!.font = UIFont(name: f.fontName, size: frame.height / 4)
    }
    
    private func constantTitle(s: String)(_: Double) -> String {
        return s
    }
    
    ///
    /// Sets the button title
    /// - parameter title: the new title
    ///
    func setButtonTitle(title: String) {
        button.setTitle(title, forState: UIControlState.Normal)
    }
    
    ///
    /// Sets title that will stay regardless of time
    /// - parameter title: the new title
    ///
    func setConstantTitle(title: String) {
        button.setTitle(title, forState: UIControlState.Normal)
        textTransform = constantTitle(title)
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
        circularProgressBarView.emptyLineColor = colourScheme.darker.tint
    }
    
    ///
    /// Starts a timer for the given ``duration``, calling ``onTimerElapsed`` at the end
    /// - parameter duration: the duration
    /// - parameter onTimerElapsed: function to be called when the timer is up
    ///
    func start(duration: NSTimeInterval, onTimerElapsed: Event? = nil) {
        timer?.invalidate()
        timer = nil
        timerChanged = true
        circularProgressBarView.hidden = false
        circularProgressBarView.maxValue = CGFloat(duration)
        let ttd = timeToDisplay(duration: duration, elapsed: 0)
        circularProgressBarView.value = CGFloat(ttd)
        button.setTitle(textTransform(ttd), forState: UIControlState.Normal)

        self.start = NSDate()
        self.duration = duration
        self.onTimerElapsed = onTimerElapsed
        self.timer = NSTimer.scheduledTimerWithTimeInterval(0.5, target: self, selector: "onTimerTick", userInfo: nil, repeats: true)
    }
    
    ///
    /// Resets the counter and stops the timer
    ///
    func stop() {
        timer?.invalidate()
        timer = nil
        
        circularProgressBarView.value = 0
        circularProgressBarView.hidden = true
    }
    
    @IBAction func onButtonTouched() {
        if let buttonTouched = buttonTouched {
            if buttonTouchResets { stop() }
            buttonTouched(self)
        }
    }
    
    private func timeToDisplay(duration duration: NSTimeInterval, elapsed: NSTimeInterval) -> NSTimeInterval {
        switch countingStyle {
        case .Elapsed: return elapsed
        case .Remaining: return max(duration - elapsed, 0)
        }
    }
    
    ///
    /// Intended to be called on timer tick; do not call explicitly
    ///
    func onTimerTick() {
        if timer == nil { return }
        guard let start = start, duration = duration else { return }
        timerChanged = false
        let elapsed = -start.timeIntervalSinceNow
        if elapsed > duration {
            if elapsedResets { stop() }
            if let event = onTimerElapsed { event(self) }
        }
        // timerChanged might now be true if restarted by event
        // in this case do not play the animation
        if !timerChanged && (!elapsedResets || elapsed < duration) {
            let ttd = timeToDisplay(duration: duration, elapsed: elapsed)
            circularProgressBarView.setValue(CGFloat(ttd), animateWithDuration: 0.5)
            button.setTitle(textTransform(ttd), forState: UIControlState.Normal)
        }
    }
    
    
}
