import UIKit

@IBDesignable
class MRAlternativeButton: UIButton {
    
    @IBInspectable
    var color: UIColor = MRColor.gray {
        didSet {
            layer.borderColor = color.CGColor
        }
    }
    
    @IBInspectable
    var lineWidth: NSNumber? {
        didSet {
            layoutIfNeeded()
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let radius = min(frame.width, frame.height) / 2
        let radius16 = radius / 16
        let lineWidth = CGFloat(self.lineWidth?.floatValue ?? radius16)
        
        titleLabel?.numberOfLines = 3
        titleLabel?.lineBreakMode = .ByWordWrapping
        titleLabel?.textAlignment = .Center
        titleLabel?.adjustsFontSizeToFitWidth = true
        titleLabel?.font = titleLabel?.font.fontWithSize(min(4.2 * radius16, 28))
        
        titleEdgeInsets = UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8)
        
        layer.cornerRadius = radius
        layer.borderWidth = lineWidth
        layer.borderColor = color.CGColor

        if imageView?.image != nil {
            let top = 0.7 * frame.height
            let r = radius * 0.7
            let h = (frame.height - top - r) / 2
            let x = (frame.width - r) / 2
            
            imageView?.tintColor = titleColorForState(.Normal)
            imageEdgeInsets = UIEdgeInsets(top: top + h, left: x, bottom: h, right: x)
            contentEdgeInsets = UIEdgeInsets(top: 4, left: 8, bottom: 12, right: 8)
            titleLabel?.frame = frame
        }
    }
    
}