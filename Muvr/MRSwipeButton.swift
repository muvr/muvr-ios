import Foundation
import UIKit

///
/// Draws a "chevron" button with a (<) or (>) symbol, depending on the value of the ``forward`` property.
///
@IBDesignable
class MRSwipeButton: UIButton {
    
    /// When ``true``, display the (>) symbol; otherwise, display the (<) symbol
    @IBInspectable
    var forward: Bool = true {
        didSet {
            if forward { accessibilityLabel = "Swipe Right" }
            else { accessibilityLabel = "Swipe Left" }
        }
    }
    
    @IBInspectable
    var lineWidth: Float = 2 {
        didSet{
            setNeedsDisplay()
        }
    }
    
    private let shapeLayer = CAShapeLayer()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        createUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        createUI()
    }
    
    private func createUI() {
        shapeLayer.opaque = false
        titleLabel?.removeFromSuperview()
    }
    
    override func drawRect(rect: CGRect) {
        let path = UIBezierPath()
        let line = CGFloat(lineWidth)
        let zero = ceil(line / 2)
        let w = frame.width - line
        let h = frame.height - line
        if forward {
            path.moveToPoint(CGPointMake(zero, zero))
            path.addLineToPoint(CGPointMake(zero + w, zero + h / 2))
            path.addLineToPoint(CGPointMake(zero, zero + h))
        } else {
            path.moveToPoint(CGPointMake(zero + w, zero))
            path.addLineToPoint(CGPointMake(zero, zero + h / 2))
            path.addLineToPoint(CGPointMake(zero + w, zero + h))
        }
        path.lineCapStyle = .Round
        path.lineWidth = line
        shapeLayer.path = path.CGPath
        shapeLayer.strokeColor = self.tintColor.CGColor
        path.stroke()
    }
    
}
