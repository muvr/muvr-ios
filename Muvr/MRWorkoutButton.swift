import UIKit

@IBDesignable
class MRWorkoutButton: UIButton {

    @IBInspectable
    var color: UIColor = UIColor.darkTextColor() {
        didSet {
            layer.borderColor = color.CGColor
        }
    }
    
    var session: MRSessionType? = nil {
        didSet {
            let title = session.map { "Start \($0.name)" }
            accessibilityLabel = title
            accessibilityHint = "Workout".localized()
            setTitle(title, forState: .Normal)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let radius = min(frame.width, frame.height) / 2
        let lineWidth = radius / 16
        
        titleLabel?.numberOfLines = 3
        titleLabel?.lineBreakMode = .ByWordWrapping
        titleLabel?.textAlignment = .Center
        titleLabel?.adjustsFontSizeToFitWidth = true
        titleLabel?.font = titleLabel?.font.fontWithSize(4 * lineWidth)
        
        titleEdgeInsets = UIEdgeInsets(top: 6, left: 12, bottom: 6, right: 12) 
        
        layer.cornerRadius = radius
        layer.borderWidth = lineWidth
        layer.borderColor = color.CGColor
    }
    
}