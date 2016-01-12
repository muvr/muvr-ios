import Foundation
import UIKit

@IBDesignable
class MRWeightView: UIView {

    private let label: UILabel = UILabel()
    
    private let iconLayer: CAShapeLayer = CAShapeLayer()
    
    private var lineWidth: CGFloat {
        return min(frame.width, frame.height) / 16
    }
    
    @IBInspectable
    var value: Double? {
        get { return _value }
        set(v) {
            _value = v.map { max(0, $0) }
            label.text = v.map { NSMassFormatter().stringFromKilograms($0) } ?? nil
        }
    }
    
    var _value: Double? = nil
        
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
        let radius = min(frame.width, frame.height) / 10
        label.frame = CGRectMake(0, 2 * radius, frame.width, frame.height - 2 * radius)
        label.textAlignment = .Center
        label.textColor = UIColor.blackColor()
        label.font = label.font.fontWithSize(fontSize)
    }
    
    private func drawIcon() {
        let path = UIBezierPath()
        let center = CGPointMake(CGRectGetMidX(self.bounds) , CGRectGetMidY(self.bounds))
        let radius = min(frame.width, frame.height) / 7
        let lineWidth = radius / 3
        
        let left = lineWidth / 2
        let right = frame.width - lineWidth / 2
        let top = lineWidth / 2 + 2 * radius
        let bottom = frame.height - lineWidth / 2
        let middleLeft = left + frame.width / 8
        let middleRight = right - frame.width / 8
        
        iconLayer.strokeColor = iconLayer.fillColor

        path.moveToPoint(CGPoint(x: middleLeft, y: top))
        path.addLineToPoint(CGPoint(x: middleRight, y: top))
        path.moveToPoint(CGPoint(x: middleRight, y: top))
        path.addLineToPoint(CGPoint(x: right, y: bottom))
        path.moveToPoint(CGPoint(x: right, y: bottom))
        path.addLineToPoint(CGPoint(x: left, y: bottom))
        path.moveToPoint(CGPoint(x: left, y: bottom))
        path.addLineToPoint(CGPoint(x: middleLeft, y: top))

        
        
        path.moveToPoint(CGPoint(x: center.x, y: top))
        path.addArcWithCenter(CGPoint(x: center.x, y: top - radius), radius: radius, startAngle: CGFloat(M_PI_2), endAngle: 5 * CGFloat(M_PI_2), clockwise: true)
        
        path.lineWidth = lineWidth
        path.lineCapStyle = .Round
        
        iconLayer.path = path.CGPath
        path.stroke()
        
//        let circle = UIBezierPath(arcCenter: CGPoint(x: center.x, y: top - radius), radius: radius, startAngle: 0, endAngle: 2 * CGFloat(M_PI), clockwise: true)
//        circle.lineWidth = lineWidth
//        circle.lineCapStyle = .Round
//        circle.stroke()
    }
    
}
