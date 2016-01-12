import Foundation
import UIKit
import MuvrKit

class MRAlternateExerciseButton: UIButton {

    //let circleLayer = CAShapeLayer()
    
    var exercise: MKIncompleteExercise? = nil {
        didSet {
            setTitle(exercise?.title, forState: .Normal)
        }
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
     //   layer.addSublayer(circleLayer)
     //   circleLayer.fillColor = UIColor.clearColor().CGColor
     //   circleLayer.opaque = false
        titleLabel?.numberOfLines = 4
        titleLabel?.textAlignment = .Center
        setTitleColor(UIColor.blackColor(), forState: .Normal)
    }
    
    override func drawRect(rect: CGRect) {
        let radius = min(frame.width, frame.height) / 2
        let center = CGPointMake(CGRectGetMidX(bounds) , CGRectGetMidY(bounds))
        let lineWidth = radius / 16
        let path = UIBezierPath()
        path.addArcWithCenter(center, radius: radius - lineWidth / 2, startAngle: 0, endAngle: 2 * CGFloat(M_PI), clockwise: true)
        path.lineCapStyle = .Round
        path.lineWidth = lineWidth
        path.stroke()
        
        titleLabel?.frame = CGRectMake(5 * lineWidth, 5 * lineWidth, bounds.width - 10 * lineWidth, bounds.height - 10 * lineWidth)
    }
    
}
