import UIKit

extension UIView {
    
    func rotate(duration: NSTimeInterval = 1.0, delegate: AnyObject? = nil) {
        let animation = CABasicAnimation(keyPath: "transform.rotation")
        animation.fromValue = 0.0
        animation.toValue = 2.0 * M_PI
        animation.duration = duration
        
        if let delegate = delegate {
            animation.delegate = delegate
        }
        
        self.layer.addAnimation(animation, forKey: nil)
    }
    
}