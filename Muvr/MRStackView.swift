import Foundation
import QuartzCore
import UIKit

class MRStackView: UIView {

    var stackWidth: Int = 32 {
        didSet { setNeedsDisplay() }
    }
    
    var stackPadding: Int = 4 {
        didSet { setNeedsDisplay() }
    }
    
    private var sWidth: Int {
        return stacks.isEmpty ? stackWidth : min(stackWidth, Int(frame.width) / stacks.count - stackPadding)
    }
    
    private var stacks: [MRCAStackLayer] = []
    
    private var maxReps: Int {
        let maxCount = stacks.reduce(0) { count, stack in
            return max(count, stack.instanceCount)
        }
        return max(10, maxCount)
    }

    override var frame: CGRect {
        didSet { setNeedsDisplay() }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.opaque = false
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func drawRect(rect: CGRect) {
        redraw()
    }
    
    func redraw() {
        stacks.enumerate().forEach { index, stack in
            stack.max = maxReps
            stack.frame = stackFrame(index)
            stack.setNeedsDisplay()
        }
    }
    
    private func stackFrame(index: Int) -> CGRect {
        let barHeight = bounds.height / CGFloat(maxReps)
        return CGRect(
            x: bounds.origin.x + bounds.width - CGFloat((index + 1) * (sWidth + stackPadding)) - CGFloat(stackPadding),
            y: bounds.origin.y,
            width: CGFloat(sWidth),
            height: bounds.height - barHeight / 2
        )
    }
    
    func addStack(color color: UIColor, count: Int) {
        let stack = MRCAStackLayer()
        stack.contentsScale = UIScreen.mainScreen().scale
        stacks.append(stack)
        layer.addSublayer(stack)
        stack.color = color
        stack.instanceCount = count
        redraw()
    }
    
    func empty() {
        stacks.forEach { $0.removeFromSuperlayer() }
        stacks.removeAll()
        redraw()
    }
}

private class MRCAStackLayer: CAReplicatorLayer {
    
    private let barLayer: CALayer = CALayer()
    
    var max: Int = 10 {
        didSet { setNeedsDisplay() }
    }
    
    var color: UIColor = UIColor.clearColor() {
        didSet { setNeedsDisplay() }
    }
    
    override var instanceCount: Int {
        didSet { setNeedsDisplay() }
    }
    
    override init() {
        super.init()
        self.opaque = false
        addSublayer(barLayer)
    }
    
    override init(layer: AnyObject) {
        super.init(layer: layer)
        self.opaque = false
        addSublayer(barLayer)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func drawInContext(ctx: CGContext) {
        let max = CGFloat(self.max)
        let barHeight = 0.8 * bounds.height / max
        barLayer.backgroundColor = color.CGColor
        barLayer.cornerRadius = barHeight / 4
        barLayer.frame = CGRect(x: 0, y: bounds.height - barHeight, width: bounds.width, height: barHeight)
        
        instanceRedOffset = -0.01
        instanceBlueOffset = -0.02
        instanceGreenOffset = -0.03
        instanceTransform = CATransform3DMakeTranslation(0, -bounds.height / CGFloat(max), 0)
    }
}