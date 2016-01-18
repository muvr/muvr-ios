import Foundation
import UIKit
import MuvrKit

@IBDesignable
class MRBarsView: UIView {
    
    @IBInspectable
    var bars: Int = 5 {
        didSet {
            setNeedsDisplay()
        }
    }
    
    @IBInspectable
    var value: Double? {
        didSet {
            setNeedsDisplay()
        }
    }
    
    @IBInspectable
    var barColor: UIColor = UIColor.blackColor() {
        didSet {
            setNeedsDisplay()
        }
    }
    
    @IBInspectable
    var emptyBarColor: UIColor = UIColor.clearColor() {
        didSet {
            setNeedsDisplay()
        }
    }
    
    private var lineWidth: CGFloat {
        return frame.width / CGFloat(2 * (bars + 1))
    }
    
    private let barsLayer = CAShapeLayer()
    
    private var barsPath: UIBezierPath? {
        guard let path = barsLayer.path else { return nil }
        return UIBezierPath(CGPath: path)
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
        barsLayer.opaque = false
        barsLayer.fillColor = UIColor.clearColor().CGColor
        layer.addSublayer(barsLayer)
    }
    
    override func drawRect(rect: CGRect) {
        let path = UIBezierPath()
        path.lineWidth = lineWidth
        path.lineCapStyle = .Round
        
        func drawBar(atIndex index: Int) {
            let x = 2 * lineWidth * CGFloat(index)
            let bottom = frame.height - lineWidth / 2
            let top = lineWidth / 2 + (frame.height - lineWidth) * CGFloat(bars - index) / CGFloat(bars)
            path.moveToPoint(CGPoint(x: x, y: top))
            path.addLineToPoint(CGPoint(x: x, y: bottom))
        }
        
        let barsToDisplay = Int(Double(bars) * (value ?? 0))
        for i in 0..<bars {
            if i < barsToDisplay {
                drawBar(atIndex: i + 1)
            }
        }
        
        barsLayer.strokeColor = barColor.CGColor
        barsLayer.path = path.CGPath
        path.stroke()
    }
    
}
