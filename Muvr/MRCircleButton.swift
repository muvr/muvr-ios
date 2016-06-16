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
    var increase: Bool = true {
        didSet {
            if increase {
                accessibilityLabel = "Increase"
            } else {
                accessibilityLabel = "Decrease"
            }
        }
    }
    
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
        accessibilityHint = "Update value"
        layer.addSublayer(circleLayer)
        circleLayer.fillColor = UIColor.clear().cgColor
        circleLayer.isOpaque = false
        titleLabel?.isHidden = true
        titleLabel?.text = nil
    }
    
    override func draw(_ rect: CGRect) {
        let radius = min(frame.width, frame.height) / 2
        let center = CGPoint(x: bounds.midX , y: bounds.midY)
        let lineWidth = radius / 16
        let path = UIBezierPath()
        let padding = 0.35 * radius
        path.addArc(withCenter: center, radius: radius - lineWidth / 2, startAngle: 0, endAngle: 2 * CGFloat(M_PI), clockwise: true)
        
        path.move(to: CGPoint(x: center.x - padding, y: center.y))
        path.addLine(to: CGPoint(x: center.x + padding, y: center.y))
        if increase {
            path.move(to: CGPoint(x: center.x, y: center.y - padding))
            path.addLine(to: CGPoint(x: center.x, y: center.y + padding))
        }
        path.lineCapStyle = .round
        path.lineWidth = lineWidth
        circleLayer.path = path.cgPath
        circleLayer.strokeColor = self.tintColor.cgColor
        path.stroke()
    }
    
}
