import UIKit
import MuvrKit

/// Provides callbacks for the users of the ``MRExerciseView``
protocol MRExerciseViewDelegate {
    
    /// Called when the exercise button is tapped
    /// - parameter exerciseView: the view where the tap originated
    func exerciseViewTapped(exerciseView: MRExerciseView)
    
    /// Called when the exercise button is long-tapped
    /// - parameter exerciseView: the view where the long tap originated
    func exerciseViewLongTapped(exerciseView: MRExerciseView)
    
    /// Called when the circle animation gets to the end
    /// - parameter exerciseView: the view that has finished animating
    func exerciseViewCircleDidComplete(exerciseView: MRExerciseView)
    
    /// Called when the exercise button is swiped
    /// - parameter exerciseView: the view where the swipe occured
    /// - parameter direction: the swipe direction 
    func exerciseViewSwiped(exerciseView: MRExerciseView, direction: UISwipeGestureRecognizerDirection)
}

///
/// Displays a button with a progress ring around it, displaying details of an
/// exercise to be performed or being performed.
///
/// It can be used to display upcoming exercise. Tapping the button triggers
/// transition to _in exercise_. Tapping the button then will cause transition
/// to done exercising.
///
/// The crucial property is ``exercise``, which allows the user to get or set
/// the exercise to be displayed.
///
@IBDesignable
class MRExerciseView : UIView, UIGestureRecognizerDelegate {
    
    var view: UIView!
    var delegate: MRExerciseViewDelegate?
    
    @IBOutlet private weak var button: UIButton!
    @IBOutlet private weak var headerLabel: UILabel!
    @IBOutlet private weak var labelsView: UIScrollView!
        
    /// set progress colors
    var progressEmptyColor : UIColor = MRColor.gray
    var progressFullColor : UIColor = UIColor.clearColor() {
        didSet {
            let animation = CABasicAnimation(keyPath: "strokeColor")
            animation.fromValue = circleLayer.strokeColor
            animation.toValue = progressFullColor.CGColor
            animation.duration = 0.3
            circleLayer.strokeColor = progressFullColor.CGColor
            circleLayer.addAnimation(animation, forKey: "animateColor")
        }
    }
    
    private let lineWidth: CGFloat = 4
    
    private var longTapped: Bool = false
    /* Controlling progress bar animation with isAnimating */
    private var isAnimating: Bool = false
    private var fireCircleDidComplete: Bool = true
    
    /// circle animation
    private var animationStartTime: CFTimeInterval? = nil
    private var animationPauseTime: CFTimeInterval? = nil
    private var animationDuration: CFTimeInterval? = nil
    private var elapsedTime: CFTimeInterval {
        return (animationPauseTime ?? 0) - (animationStartTime ?? 0)
    }

    private let circleLayer: CAShapeLayer = CAShapeLayer()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        createUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        createUI()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        button.layer.cornerRadius = (frame.height - 8) / 2
        let f = button.titleLabel!.font
        button.titleLabel!.font = UIFont(name: f.fontName, size: frame.height / 8)
        headerLabel.font = UIFont(name: f.fontName, size: frame.height / 12)
    }
    
    override func drawRect(rect: CGRect) {
        addCirle(bounds.width + 10, capRadius: lineWidth, color: progressEmptyColor, strokeStart: 0.0, strokeEnd: 1.0)
        createProgressCircle()
    }
    
    override func animationDidStart(anim: CAAnimation) {
        if isCircleAnimation(anim) {
            circleLayer.strokeColor = progressFullColor.CGColor
            isAnimating = true
            if animationDuration == nil { // new animation started
                animationStartTime = CACurrentMediaTime()
                animationDuration = anim.duration
            } else { // animation was playing
                animationStartTime = CACurrentMediaTime() - elapsedTime // discard paused time
            }
            animationPauseTime = animationStartTime
        }
    }
    
    override func animationDidStop(anim: CAAnimation, finished: Bool) {
        isAnimating = false
        
            if finished {
                animationStartTime = nil
                animationPauseTime = nil
                animationDuration = nil
                if fireCircleDidComplete { delegate?.exerciseViewCircleDidComplete(self) }
            }
        
    }
    
    private func isCircleAnimation(anim: CAAnimation) -> Bool {
        if let circleAnim = circleLayer.animationForKey("animateCircle") {
            return circleAnim == anim
        }
        return false
    }
    
    private func createUI() {
        accessibilityIdentifier = "Exercise control"
        
        view = loadViewFromNib()
        view.frame = bounds
        view.autoresizingMask = [UIViewAutoresizing.FlexibleWidth, UIViewAutoresizing.FlexibleHeight]
        view.backgroundColor = UIColor.clearColor()
        backgroundColor = UIColor.clearColor()
        
        headerLabel.text = ""
        button.setTitle("", forState: UIControlState.Normal)
        
        addSubview(view)
        updateUI()
        
        let recognizer = UILongPressGestureRecognizer(target: self, action: #selector(MRExerciseView.buttonDidLongPress))
        recognizer.minimumPressDuration = 4
        recognizer.allowableMovement = 100
        button.addGestureRecognizer(recognizer)
    }
    
    private func loadViewFromNib() -> UIView {
        let bundle = NSBundle(forClass: self.dynamicType)
        let nib = UINib(nibName: "MRExerciseView", bundle: bundle)
        
        // Assumes UIView is top level and only object in CustomView.xib file
        let view = nib.instantiateWithOwner(self, options: nil)[0] as! UIView

        return view
    }
    
    private func addCirle(arcRadius: CGFloat, capRadius: CGFloat, color: UIColor, strokeStart: CGFloat, strokeEnd: CGFloat) {
        let centerPoint = CGPointMake(CGRectGetMidX(self.bounds) , CGRectGetMidY(self.bounds))
        let startAngle = CGFloat(M_PI_2)
        let endAngle = CGFloat(M_PI * 2 + M_PI_2)
        
        let path = UIBezierPath(arcCenter:centerPoint, radius: (CGRectGetWidth(frame) - 4 * lineWidth) / 2 + 5, startAngle:startAngle, endAngle:endAngle, clockwise: true).CGPath

        let arc = CAShapeLayer()
        arc.lineWidth = lineWidth
        arc.path = path
        arc.strokeStart = strokeStart
        arc.strokeEnd = strokeEnd
        arc.strokeColor = color.CGColor
        arc.fillColor = UIColor.clearColor().CGColor
        arc.shadowColor = MRColor.black.CGColor
        arc.shadowRadius = 0
        arc.shadowOpacity = 0
        arc.shadowOffset = CGSizeZero
        layer.addSublayer(arc)
    }
    
    private func createProgressCircle() {
        let centerPoint = CGPointMake(CGRectGetMidX(self.bounds) , CGRectGetMidY(self.bounds))
        let startAngle = CGFloat(M_PI_2)
        let endAngle = CGFloat(M_PI * 2 + M_PI_2)
        
        // Use UIBezierPath as an easy way to create the CGPath for the layer.
        // The path should be the entire circle.
        let circlePath = UIBezierPath(arcCenter:centerPoint, radius: (CGRectGetWidth(frame) - 4 * lineWidth) / 2 + 5, startAngle:startAngle, endAngle:endAngle, clockwise: true).CGPath
        
        // Setup the CAShapeLayer with the path, colors, and line width

        circleLayer.path = circlePath
        circleLayer.fillColor = UIColor.clearColor().CGColor
        circleLayer.shadowColor = MRColor.black.CGColor
        circleLayer.strokeColor = self.progressFullColor.CGColor
        circleLayer.lineWidth = lineWidth * 4
        circleLayer.strokeStart = 0.0
        circleLayer.shadowRadius = 1
        circleLayer.shadowOpacity = 0
        circleLayer.shadowOffset = CGSizeZero
        circleLayer.lineCap = kCALineCapRound
        
        // Don't draw the circle initially
        circleLayer.strokeEnd = 0.0
        
        // Add the circleLayer to the view's layer's sublayers
        layer.addSublayer(circleLayer)
    }
    
    private func animateCircle(duration: NSTimeInterval) {
        // We want to animate the strokeEnd property of the circleLayer
        let animation = CABasicAnimation(keyPath: "strokeEnd")
        
        // Set the animation duration appropriately
        animation.duration = duration - elapsedTime
        
        // Animate from 0 (no circle) to 1 (full circle)
        animation.fromValue =  elapsedTime / duration
        animation.toValue = 1
        animation.delegate = self
        // Do a linear animation (i.e. the speed of the animation stays the same)
        animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)
        
        // Set the circleLayer's strokeEnd property to 1.0 now so that it's the
        // right value when the animation ends.

        circleLayer.strokeEnd = 1.0
        
        // Do the actual animation
        circleLayer.addAnimation(animation, forKey: "animateCircle")
    }
    
    private func pauseLayer(layer: CALayer) {
        let pauseTime = layer.convertTime(CACurrentMediaTime(), fromLayer: nil)
        layer.speed = 0.0
        layer.timeOffset = pauseTime
    }
    
    private func resumeLayer(layer: CALayer) {
        let pausedTime = layer.timeOffset
        layer.speed = 1.0
        layer.timeOffset = 0.0
        layer.beginTime = 0.0
        let timeSincePause = layer.convertTime(CACurrentMediaTime(), fromLayer: nil) - pausedTime
        layer.beginTime = timeSincePause
    }
    
    private var buttonFontSize: CGFloat {
        guard let exerciseDetail = exerciseDetail else { return button.titleLabel!.font.pointSize }
        
        let text = MKExercise.title(exerciseDetail.id)
        let font = button.titleLabel!.font
        var fontSize = frame.height / 8
        var size = text.sizeWithAttributes([NSFontAttributeName: font.fontWithSize(fontSize)])
        while (size.width > button.bounds.width - 6 * lineWidth) {
            fontSize -= 1
            size = text.sizeWithAttributes([NSFontAttributeName: font.fontWithSize(fontSize)])
        }
        return fontSize
    }
    

    private func updateUI() {
        let title = exerciseDetail.map { MKExercise.title($0.id) }
        button.setTitle(title, forState: UIControlState.Normal)
        button.titleLabel?.font = UIFont.systemFontOfSize(buttonFontSize)
        button.titleEdgeInsets = UIEdgeInsets()
        
        accessibilityLabel = title

        labelsView.subviews.forEach { $0.removeFromSuperview() }
        labelsView.pagingEnabled = true
        
        let padding: CGFloat = 10
        let height: CGFloat = ceil(labelsView.frame.height / 2)
        let width: CGFloat = height + padding
        let allWidth: CGFloat = CGFloat((exerciseLabels?.count ?? 0) + (exerciseDuration == nil ? 0 : 1)) * width
        var left: CGFloat = 0
        
        if let exerciseLabels = exerciseLabels {
            
            if allWidth < labelsView.frame.width {
                left = ceil((labelsView.frame.width - allWidth) / 2)
            }
            
            for exerciseLabel in exerciseLabels {
                let frame = CGRect(x: left, y: 0, width: width - padding, height: height - padding)
                left += width
                let (view, _) = MRExerciseLabelViews.scalarViewForLabel(exerciseLabel, frame: frame)!
                labelsView.addSubview(view)
            }
        }
        
        if let duration = exerciseDuration {
            let frame = CGRect(x: left, y: 0, width: width - padding, height: height - padding)
            let view = MRExerciseLabelViews.scalarViewForDuration(duration, frame: frame)
            labelsView.addSubview(view)
        }
    }
    
    
    @IBAction private func buttonDidPressed(sender: UIButton) {
        delegate?.exerciseViewTapped(self)
    }
    
    @IBAction private func buttonDidSwipe(recognizer: UISwipeGestureRecognizer) {
        delegate?.exerciseViewSwiped(self, direction: recognizer.direction)
    }
    
    func buttonDidLongPress() {
        if !longTapped {
            delegate?.exerciseViewLongTapped(self)
            longTapped = true
        }
    }

    // MARK: - public API
    
    var exerciseLabels: [MKExerciseLabel]? = [] {
        didSet {
            UIView.performWithoutAnimation(updateUI)
        }
    }
    
    var exerciseDuration: NSTimeInterval? = nil {
        didSet {
            UIView.performWithoutAnimation(updateUI)
        }
    }
    
    ///
    /// The exercise being displayed
    ///
    var exerciseDetail: MKExerciseDetail? {
        didSet {
            UIView.performWithoutAnimation(updateUI)
        }
    }
    
    var headerTitle: String? {
        didSet {
            accessibilityHint = headerTitle
            headerLabel.text = headerTitle
        }
    }
    
    /// Starts the animation for the given duration
    func start(duration: NSTimeInterval) {
        fireCircleDidComplete = true
        if !isAnimating {
            animateCircle(duration)
        } else {
            resumeLayer(circleLayer)
        }
    }
    
    /// Reset the animation
    func reset() {
        layer.removeAnimationForKey("animateCircle")
        isAnimating = false
        animationStartTime = nil
        animationPauseTime = nil
        animationDuration = nil
        fireCircleDidComplete = false
        circleLayer.strokeColor = UIColor.clearColor().CGColor
    }
    
}
