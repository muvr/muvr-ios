import UIKit

@IBDesignable
class MRAlternativeButton: UIButton {
    
    @IBInspectable
    var color: UIColor = MRColor.gray {
        didSet {
            layer.borderColor = color.CGColor
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
        titleLabel?.font = titleLabel?.font.fontWithSize(4.2 * lineWidth)
        
        titleEdgeInsets = UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8)
        
        layer.cornerRadius = radius
        layer.borderWidth = lineWidth
        layer.borderColor = color.CGColor
    }
    
}