import Foundation
import UIKit

///
/// Draws a round button with a (+) or (-) symbol, depending on the value of the ``increase`` property.
/// This turns out to be visually more pleasing than the alternative, which is simply a normal button with
/// layer.borderRadius = x, and the text "+" or "-".
///
@IBDesignable
class MRCircleButton: UIButton {

    /// When ``true``, display the (+) symbol; otherwise, display the (-) symbol
    @IBInspectable
    var increase: Bool = true
    
    private let circleLayer = CAShapeLayer()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        createUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        createUI()
    }
    
    private func createUI() {
        layer.addSublayer(circleLayer)
        circleLayer.fillColor = UIColor.clearColor().CGColor
        circleLayer.opaque = false
        titleLabel?.hidden = true
        titleLabel?.text = nil
    }
    
    override func drawRect(rect: CGRect) {
        let radius = min(frame.width, frame.height) / 2
        let center = CGPointMake(CGRectGetMidX(bounds) , CGRectGetMidY(bounds))
        let lineWidth = radius / 10
        let path = UIBezierPath()
        path.addArcWithCenter(center, radius: radius - lineWidth / 2, startAngle: 0, endAngle: 2 * CGFloat(M_PI), clockwise: true)
        path.moveToPoint(CGPoint(x: center.x - radius / 2, y: center.y))
        path.addLineToPoint(CGPoint(x: center.x + radius / 2, y: center.y))
        if increase {
            path.moveToPoint(CGPoint(x: center.x, y: center.y - radius / 2))
            path.addLineToPoint(CGPoint(x: center.x, y: center.y + radius / 2))
        }
        path.lineCapStyle = .Round
        path.lineWidth = lineWidth
        circleLayer.path = path.CGPath
        circleLayer.strokeColor = self.tintColor.CGColor
        path.stroke()
    }
    
}
