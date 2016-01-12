import Foundation
import UIKit

@IBDesignable
class MRRepetitionsView: UIView {
    
    private let label: UILabel = UILabel()
    
    private let iconLayer: CAShapeLayer = CAShapeLayer()
    
    private var lineWidth: CGFloat {
        return min(frame.width, frame.height) / 16
    }
    
    @IBInspectable
    var value: Int? {
        get { return _value }
        set(v) {
            _value = v.map { max(0, $0) }
            label.text = v.map { NSNumberFormatter().stringFromNumber($0) } ?? nil
        }
    }
    
    var _value: Int? = nil
    
    var font: UIFont = UIFont.systemFontOfSize(17) {
        didSet {
            label.font = font
        }
    }
    
    private var fontSize: CGFloat {
        guard let text = label.text else { return label.font.pointSize }
        let font = label.font
        var fontSize = frame.height / 2
        var size = text.sizeWithAttributes([NSFontAttributeName: font.fontWithSize(fontSize)])
        while (size.width > bounds.width - 6 * lineWidth) {
            fontSize -= 1
            size = text.sizeWithAttributes([NSFontAttributeName: font.fontWithSize(fontSize)])
        }
        return fontSize
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        createUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        createUI()
    }
    
    private func createUI() {
        iconLayer.opaque = false
        iconLayer.fillColor = UIColor.clearColor().CGColor
        layer.addSublayer(iconLayer)
        addSubview(label)
    }
    
    override func drawRect(rect: CGRect) {
        drawIcon()
        label.frame = bounds
        label.textAlignment = .Center
        label.font = label.font.fontWithSize(fontSize)
    }
    
    private func drawIcon() {
        let arrowSize = min(frame.width, frame.height) / 8
        let cornerRadius = arrowSize
        let path = UIBezierPath()
        let center = CGPointMake(CGRectGetMidX(self.bounds) , CGRectGetMidY(self.bounds))
        
        let lineWidth = arrowSize / 2
        let left = lineWidth / 2
        let top = lineWidth / 2 + arrowSize
        let bottom = frame.height - lineWidth / 2 - arrowSize
        let middleLeft = center.x - frame.width / 8
        let middleRight = center.x + frame.width / 8
        let right = frame.width - lineWidth / 2
        
        path.moveToPoint(CGPoint(x: middleLeft, y: bottom))
        path.addLineToPoint(CGPoint(x: left + cornerRadius, y: bottom))
        path.addArcWithCenter(CGPoint(x: left + cornerRadius, y: bottom - cornerRadius), radius: cornerRadius, startAngle: CGFloat(M_PI_2), endAngle: CGFloat(M_PI), clockwise: true)
        path.addLineToPoint(CGPoint(x: left, y: top + cornerRadius))
        path.addArcWithCenter(CGPoint(x: left + cornerRadius, y: top + cornerRadius), radius: cornerRadius, startAngle: CGFloat(M_PI), endAngle: 3 * CGFloat(M_PI_2), clockwise: true)
        path.addLineToPoint(CGPoint(x: middleLeft, y: top))
        path.moveToPoint(CGPoint(x: middleLeft, y: top))
        path.addLineToPoint(CGPoint(x: middleLeft - arrowSize, y: top - arrowSize))
        path.moveToPoint(CGPoint(x: middleLeft, y: top))
        path.addLineToPoint(CGPoint(x: middleLeft - arrowSize, y: top + arrowSize))
        
        path.moveToPoint(CGPoint(x: middleRight, y: top))
        path.addLineToPoint(CGPoint(x: right - cornerRadius, y: top))
        path.addArcWithCenter(CGPoint(x: right - cornerRadius, y: top + cornerRadius), radius: cornerRadius, startAngle: 3 * CGFloat(M_PI_2), endAngle: 2 * CGFloat(M_PI), clockwise: true)
        path.addLineToPoint(CGPoint(x: right, y: bottom - cornerRadius))
        path.addArcWithCenter(CGPoint(x: right - cornerRadius, y: bottom - cornerRadius), radius: cornerRadius, startAngle: 0, endAngle: CGFloat(M_PI_2), clockwise: true)
        path.addLineToPoint(CGPoint(x: middleRight, y: bottom))
        path.moveToPoint(CGPoint(x: middleRight, y: bottom))
        path.addLineToPoint(CGPoint(x: middleRight + arrowSize, y: bottom + arrowSize))
        path.moveToPoint(CGPoint(x: middleRight, y: bottom))
        path.addLineToPoint(CGPoint(x: middleRight + arrowSize, y: bottom - arrowSize))
        
        
        iconLayer.strokeColor = UIColor.blackColor().CGColor
        iconLayer.path = path.CGPath
        path.lineCapStyle = .Round
        path.lineWidth = lineWidth
        path.stroke()
    }
}
