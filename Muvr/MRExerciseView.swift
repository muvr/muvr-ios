import UIKit
import MuvrKit

protocol MRExerciseViewDelegate {
    func tapped()
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
class MRExerciseView : UIView {
    
    var view: UIView!
    var delegate: MRExerciseViewDelegate?
    
    @IBOutlet private weak var button: UIButton!
        
    /// set progress colors
    var progressEmptyColor : UIColor = UIColor.grayColor()
    var progressFullColor : UIColor = UIColor.redColor()
    
    private let lineWidth: CGFloat = 4
    
    /* Controlling progress bar animation with isAnimating */
    private var isAnimating : Bool = false

    private let circleLayer: CAShapeLayer = CAShapeLayer()

    
    /* 
     *
     * Set Images in storyBoard with IBInspectable variables
     *
     *
    @IBInspectable var coverImage: UIImage? {
        get {
            return coverImageView.image
        }
        set(coverImage) {
            coverImageView.image = coverImage
        }
    }
    */
    
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
    }
    
    override func drawRect(rect: CGRect) {
        addCirle(bounds.width + 10, capRadius: lineWidth, color: progressEmptyColor, strokeStart: 0.0, strokeEnd: 1.0)
        createProgressCircle()
    }
    
    override func animationDidStart(anim: CAAnimation) {
        circleLayer.strokeColor = progressFullColor.CGColor
        isAnimating = true
    }
    
    override func animationDidStop(anim: CAAnimation, finished flag: Bool) {
        isAnimating = false
        circleLayer.strokeColor = UIColor.clearColor().CGColor
    }
    
    private func createUI() {
        view = loadViewFromNib()
        view.frame = bounds
        view.autoresizingMask = [UIViewAutoresizing.FlexibleWidth, UIViewAutoresizing.FlexibleHeight]
        view.backgroundColor = UIColor.clearColor()
        backgroundColor = UIColor.clearColor()
        
        addSubview(view)
    }
    
    private func loadViewFromNib() -> UIView {
        let bundle = NSBundle(forClass: self.dynamicType)
        let nib = UINib(nibName: "MRExerciseView", bundle: bundle)
        
        // Assumes UIView is top level and only object in CustomView.xib file
        let view = nib.instantiateWithOwner(self, options: nil)[0] as! UIView

        return view
    }
    
    private func addCirle(arcRadius: CGFloat, capRadius: CGFloat, color: UIColor, strokeStart : CGFloat, strokeEnd : CGFloat) {

        let centerPoint = CGPointMake(CGRectGetMidX(self.bounds) , CGRectGetMidY(self.bounds))
        let startAngle = CGFloat(M_PI_2)
        let endAngle = CGFloat(M_PI * 2 + M_PI_2)
        
        let path = UIBezierPath(arcCenter:centerPoint, radius: CGRectGetWidth(frame)/2+5, startAngle:startAngle, endAngle:endAngle, clockwise: true).CGPath
        
        let arc = CAShapeLayer()
        arc.lineWidth = lineWidth
        arc.path = path
        arc.strokeStart = strokeStart
        arc.strokeEnd = strokeEnd
        arc.strokeColor = color.CGColor
        arc.fillColor = UIColor.clearColor().CGColor
        arc.shadowColor = UIColor.blackColor().CGColor
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
        let circlePath = UIBezierPath(arcCenter:centerPoint, radius: CGRectGetWidth(frame)/2+5, startAngle:startAngle, endAngle:endAngle, clockwise: true).CGPath
        
        // Setup the CAShapeLayer with the path, colors, and line width

        circleLayer.path = circlePath
        circleLayer.fillColor = UIColor.clearColor().CGColor
        circleLayer.shadowColor = UIColor.blackColor().CGColor
        circleLayer.strokeColor = self.progressFullColor.CGColor
        circleLayer.lineWidth = lineWidth * 1.5
        circleLayer.strokeStart = 0.0
        circleLayer.shadowRadius = 1
        circleLayer.shadowOpacity = 0
        circleLayer.shadowOffset = CGSizeZero
        
        // Don't draw the circle initially
        circleLayer.strokeEnd = 0.0
        
        // Add the circleLayer to the view's layer's sublayers
        layer.addSublayer(circleLayer)
    }
    
    private func animateCircle(duration: NSTimeInterval) {
        // We want to animate the strokeEnd property of the circleLayer
        let animation = CABasicAnimation(keyPath: "strokeEnd")
        
        // Set the animation duration appropriately
        animation.duration = duration
        
        // Animate from 0 (no circle) to 1 (full circle)
        animation.fromValue = 0
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
    
    private func pauseLayer(layer : CALayer) {
        let pauseTime = layer.convertTime(CACurrentMediaTime(), fromLayer: nil)
        layer.speed = 0.0
        layer.timeOffset = pauseTime
    }
    
    private func resumeLayer(layer : CALayer) {
        let pausedTime = layer.timeOffset
        layer.speed = 1.0
        layer.timeOffset = 0.0
        layer.beginTime = 0.0
        let timeSincePause = layer.convertTime(CACurrentMediaTime(), fromLayer: nil) - pausedTime
        layer.beginTime = timeSincePause
    }
    

    // MARK: - public functions

    ///
    /// The exercise being displayed
    ///
    var exercise: MKIncompleteExercise? {
        didSet {
            button.setTitle(exercise?.title, forState: UIControlState.Normal)
            // TODO: display repetitions, intensity and weight
        }
    }
    
    /// Starts the animation for the given duration
    func start(duration: NSTimeInterval) {
        if !isAnimating {
            animateCircle(duration)
        } else {
            resumeLayer(circleLayer)
        }
    }
    
    /* Stop timer and animation */
    func stop() {
        if isAnimating {
            pauseLayer(circleLayer)
        }
    }
    

    
}
