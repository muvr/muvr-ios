import UIKit

@IBDesignable
class MRAlternativeButton: UIButton {
    
    @IBInspectable
    var color: UIColor = MRColor.gray {
        didSet {
            layer.borderColor = color.cgColor
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
        titleLabel?.lineBreakMode = .byWordWrapping
        titleLabel?.textAlignment = .center
        titleLabel?.adjustsFontSizeToFitWidth = true
        // FIXME: this is broken in iOS10: it sets the font to be far too small
//        titleLabel?.font = titleLabel?.font.withSize(min(4.2 * radius16, 28))
        
        if imageView?.image != nil {
            let top = 0.7 * frame.height
            let r = radius * 0.5
            let h = (frame.height - top - r)
            let x = (frame.width - r) / 2
            
            imageView?.tintColor = titleColor(for: UIControlState())
            imageEdgeInsets = UIEdgeInsets(top: top, left: x, bottom: h, right: x)
            
            titleLabel?.frame = CGRect(x: 0, y: 0, width: frame.width, height: frame.height)
            titleEdgeInsets = UIEdgeInsets()
        } else {
            titleEdgeInsets = UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8)
        }
        
        contentVerticalAlignment = .center
        contentHorizontalAlignment = .center
        
        layer.cornerRadius = radius
        layer.borderWidth = lineWidth
        layer.borderColor = color.cgColor
    }
    
}
