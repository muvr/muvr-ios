import UIKit
import MuvrKit

/// Provides callbacks for the users of the ``MRCircleView``
@objc protocol MRCircleViewDelegate {
    
    /// Called when the main button is tapped
    /// - parameter circleView: the view where the tap originated
    @objc optional func circleViewTapped(_ circleView: MRCircleView)
    
    /// Called when the main button is long-tapped
    /// - parameter circleView: the view where the long tap originated
    @objc optional func circleViewLongTapped(_ circleView: MRCircleView)
    
    /// Called when the circle animation gets to the end
    /// - parameter circleView: the view that has finished animating
    @objc optional func circleViewCircleDidComplete(_ circleView: MRCircleView)
    
    /// Called when the main button is swiped
    /// - parameter circleView: the view where the swipe occured
    /// - parameter direction: the swipe direction (Left or Right)
    @objc optional func circleViewSwiped(_ circleView: MRCircleView, direction: UISwipeGestureRecognizerDirection)
    
}

///
/// Displays a button with a progress ring around it, displaying details of an
/// exercise or workout to be performed or being performed.
///
/// It can be used to display upcoming exercise or workout. Tapping the button triggers
/// transition to _in exercise_. Tapping the button then will cause transition
/// to done exercising.
///
@IBDesignable
class MRCircleView : UIView {
    
    var view: UIView!
    var delegate: MRCircleViewDelegate?
    
    @IBOutlet private weak var button: UIButton!
    @IBOutlet private weak var headerLabel: UILabel!
    @IBOutlet private weak var labelScrollView: UIScrollView!
    @IBOutlet private weak var swipeLeftButton: UIButton!
    @IBOutlet private weak var swipeRightButton: UIButton!
        
    /// set progress colors
    var progressEmptyColor : UIColor = MRColor.gray
    var progressFullColor : UIColor = UIColor.clear() {
        didSet {
            let animation = CABasicAnimation(keyPath: "strokeColor")
            animation.fromValue = circleLayer.strokeColor
            animation.toValue = progressFullColor.cgColor
            animation.duration = 0.3
            circleLayer.strokeColor = progressFullColor.cgColor
            circleLayer.add(animation, forKey: "animateColor")
        }
    }
    
    var swipeButtonsHidden: Bool = true {
        didSet {
            UIView.performWithoutAnimation(updateUI)
        }
    }
    
    var title: String? {
        didSet {
            button.setTitle(title, for: [])
            UIView.performWithoutAnimation(updateUI)
        }
    }
    
    /// All the label views to display inside the circle
    /// the view frames are conputed by the circle view
    var labelViews: [UIView]? {
        didSet {
            UIView.performWithoutAnimation(updateUI)
        }
    }
    
    private let lineWidth: CGFloat = 2
    
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
    /// percentage completion of the current animation
    var completion: Double {
        guard let duration = animationDuration where duration > 0 else { return 0 }
        let elapsed = CACurrentMediaTime() - (animationStartTime ?? 0)
        return elapsed / duration
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
        button.titleLabel!.font = button.titleLabel!.font.withSize(frame.height / 8)
        headerLabel.font = headerLabel.font.withSize(frame.height / 14)
    }
    
    override func draw(_ rect: CGRect) {
        addCirle(bounds.width + 10, capRadius: lineWidth, color: progressEmptyColor, strokeStart: 0.0, strokeEnd: 1.0)
        createProgressCircle()
    }
    
    override func animationDidStart(_ anim: CAAnimation) {
        if isCircleAnimation(anim) {
            circleLayer.strokeColor = progressFullColor.cgColor
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
    
    override func animationDidStop(_ anim: CAAnimation, finished: Bool) {
        isAnimating = false
        if finished {
            if fireCircleDidComplete { delegate?.circleViewCircleDidComplete?(self) }
        }
    }
    
    private func isCircleAnimation(_ anim: CAAnimation) -> Bool {
        if let circleAnim = circleLayer.animation(forKey: "animateCircle") {
            return circleAnim == anim
        }
        return false
    }
    
    private func createUI() {
        view = loadViewFromNib()
        view.frame = bounds
        view.autoresizingMask = [UIViewAutoresizing.flexibleWidth, UIViewAutoresizing.flexibleHeight]
        view.backgroundColor = UIColor.clear()
        backgroundColor = UIColor.clear()
        
        headerLabel.text = ""
        button.setTitle("", for: [])
        
        addSubview(view)
        updateUI()
        
        let recognizer = UILongPressGestureRecognizer(target: self, action: #selector(MRCircleView.buttonDidLongPress))
        recognizer.minimumPressDuration = 4
        recognizer.allowableMovement = 100
        button.addGestureRecognizer(recognizer)
    }
    
    private func loadViewFromNib() -> UIView {
        let bundle = Bundle(for: self.dynamicType)
        let nib = UINib(nibName: "MRCircleView", bundle: bundle)
        
        // Assumes UIView is top level and only object in CustomView.xib file
        let view = nib.instantiate(withOwner: self, options: nil)[0] as! UIView

        return view
    }
    
    private func addCirle(_ arcRadius: CGFloat, capRadius: CGFloat, color: UIColor, strokeStart: CGFloat, strokeEnd: CGFloat) {
        let centerPoint = CGPoint(x: self.bounds.midX , y: self.bounds.midY)
        let startAngle = CGFloat(M_PI_2)
        let endAngle = CGFloat(M_PI * 2 + M_PI_2)
        
        let path = UIBezierPath(arcCenter:centerPoint, radius: (frame.width - 4 * lineWidth) / 2 + 5, startAngle:startAngle, endAngle:endAngle, clockwise: true).cgPath

        let arc = CAShapeLayer()
        arc.lineWidth = lineWidth
        arc.path = path
        arc.strokeStart = strokeStart
        arc.strokeEnd = strokeEnd
        arc.strokeColor = color.cgColor
        arc.fillColor = UIColor.clear().cgColor
        arc.shadowColor = MRColor.black.cgColor
        arc.shadowRadius = 0
        arc.shadowOpacity = 0
        arc.shadowOffset = CGSize.zero
        layer.addSublayer(arc)
    }
    
    private func createProgressCircle() {
        let centerPoint = CGPoint(x: self.bounds.midX , y: self.bounds.midY)
        let startAngle = CGFloat(M_PI_2)
        let endAngle = CGFloat(M_PI * 2 + M_PI_2)
        
        // Use UIBezierPath as an easy way to create the CGPath for the layer.
        // The path should be the entire circle.
        let circlePath = UIBezierPath(arcCenter:centerPoint, radius: (frame.width - 4 * lineWidth) / 2 + 5, startAngle:startAngle, endAngle:endAngle, clockwise: true).cgPath
        
        // Setup the CAShapeLayer with the path, colors, and line width

        circleLayer.path = circlePath
        circleLayer.fillColor = UIColor.clear().cgColor
        circleLayer.shadowColor = MRColor.black.cgColor
        circleLayer.strokeColor = self.progressFullColor.cgColor
        circleLayer.lineWidth = lineWidth * 8
        circleLayer.strokeStart = 0.0
        circleLayer.shadowRadius = 1
        circleLayer.shadowOpacity = 0
        circleLayer.shadowOffset = CGSize.zero
        circleLayer.lineCap = kCALineCapRound
        
        // Don't draw the circle initially
        circleLayer.strokeEnd = 0.0
        
        // Add the circleLayer to the view's layer's sublayers
        layer.addSublayer(circleLayer)
    }
    
    private func animateCircle(_ duration: TimeInterval) {
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
        circleLayer.add(animation, forKey: "animateCircle")
    }
    
    private func pauseLayer(_ layer: CALayer) {
        let pauseTime = layer.convertTime(CACurrentMediaTime(), from: nil)
        layer.speed = 0.0
        layer.timeOffset = pauseTime
    }
    
    private func resumeLayer(_ layer: CALayer) {
        let pausedTime = layer.timeOffset
        layer.speed = 1.0
        layer.timeOffset = 0.0
        layer.beginTime = 0.0
        let timeSincePause = layer.convertTime(CACurrentMediaTime(), from: nil) - pausedTime
        layer.beginTime = timeSincePause
    }
    
    private var buttonFontSize: CGFloat {
        guard let text = button.titleLabel?.text else { return button.titleLabel!.font.pointSize }
        let font = button.titleLabel!.font
        var fontSize = frame.height / 8
        var size = text.size(attributes: [NSFontAttributeName: (font?.withSize(fontSize))!])
        while (size.width > button.bounds.width - 2 * swipeRightButton.bounds.width - 6 * lineWidth - 8) {
            fontSize -= 1
            size = text.size(attributes: [NSFontAttributeName: (font?.withSize(fontSize))!])
        }
        return fontSize
    }
    

    private func updateUI() {
        swipeLeftButton.isHidden = swipeButtonsHidden
        swipeRightButton.isHidden = swipeButtonsHidden
        
        button.titleLabel?.font = button.titleLabel?.font.withSize(buttonFontSize)
        
        accessibilityLabel = button.titleLabel?.text

        labelScrollView.subviews.forEach { $0.removeFromSuperview() }
        labelScrollView.isPagingEnabled = true
        
        let padding: CGFloat = 10
        let height: CGFloat = ceil(labelScrollView.frame.height / 2)
        let width: CGFloat = height + padding
        let views = labelViews ?? []
        let allWidth: CGFloat = CGFloat(views.count) * width
        var left: CGFloat = 0
        
        for view in views {
            if left == 0 && allWidth < labelScrollView.frame.width {
                left = ceil((labelScrollView.frame.width - allWidth) / 2)
            }
            
            let frame = CGRect(x: left, y: 0, width: width - padding, height: height - padding)
            left += width
            view.frame = frame
            labelScrollView.addSubview(view)
        }
    }
    
    @IBAction private func swipeLeftButtonDidPress(_ sender: UIButton) {
        delegate?.circleViewSwiped?(self, direction: .left)
    }
    
    @IBAction private func swipeRightButtonDidPress(_ sender: UIButton) {
        delegate?.circleViewSwiped?(self, direction: .right)
    }
    
    @IBAction private func buttonDidPressed(_ sender: UIButton) {
        delegate?.circleViewTapped?(self)
    }
    
    @IBAction private func buttonDidSwipe(_ recognizer: UISwipeGestureRecognizer) {
        delegate?.circleViewSwiped?(self, direction: recognizer.direction)
    }
    
    func buttonDidLongPress() {
            delegate?.circleViewLongTapped?(self)
    }

    // MARK: - public API
    
    var headerTitle: String? {
        didSet {
            accessibilityHint = headerTitle
            headerLabel.text = headerTitle
        }
    }
    
    /// Starts the animation for the given duration
    func start(_ duration: TimeInterval) {
        fireCircleDidComplete = true
        if !isAnimating {
            animateCircle(duration)
        } else {
            resumeLayer(circleLayer)
        }
    }
    
    /// Reset the animation
    func reset() {
        layer.removeAnimation(forKey: "animateCircle")
        isAnimating = false
        animationStartTime = nil
        animationPauseTime = nil
        animationDuration = nil
        fireCircleDidComplete = false
        circleLayer.strokeColor = UIColor.clear().cgColor
    }
    
}
