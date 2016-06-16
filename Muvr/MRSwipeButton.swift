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
        shapeLayer.isOpaque = false
        titleLabel?.removeFromSuperview()
    }
    
    override func draw(_ rect: CGRect) {
        let path = UIBezierPath()
        let line = CGFloat(lineWidth)
        let zero = ceil(line / 2)
        let w = frame.width - line
        let h = frame.height - line
        if forward {
            path.move(to: CGPoint(x: zero, y: zero))
            path.addLine(to: CGPoint(x: zero + w, y: zero + h / 2))
            path.addLine(to: CGPoint(x: zero, y: zero + h))
        } else {
            path.move(to: CGPoint(x: zero + w, y: zero))
            path.addLine(to: CGPoint(x: zero, y: zero + h / 2))
            path.addLine(to: CGPoint(x: zero + w, y: zero + h))
        }
        path.lineCapStyle = .round
        path.lineWidth = line
        shapeLayer.path = path.cgPath
        shapeLayer.strokeColor = self.tintColor.cgColor
        path.stroke()
    }
    
}
