import UIKit

///
/// Common replacement for UIButton with Muvr-wide properties
///
class MRButton : UIButton {
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        if let x = titleLabel?.textColor {
            layer.borderColor = x.CGColor
            layer.borderWidth = 1.5
            layer.cornerRadius = 4
            layer.masksToBounds = true
        }
    }
    
}
