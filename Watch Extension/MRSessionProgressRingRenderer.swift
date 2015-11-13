import WatchKit

class MRSessionProgressRingRenderer : NSObject {
    private let ring: MRSessionProgressRing
    private var timer: NSTimer?
    
    init(ring: MRSessionProgressRing) {
        self.ring = ring
        
        super.init()
        self.timer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: "update", userInfo: nil, repeats: true)
    }
    
    deinit {
        self.timer?.invalidate()
        self.timer = nil
    }
    
    func update() {
        if let (_, props) = MRExtensionDelegate.sharedDelegate().currentSession {
            let duration = props.duration
            let outerFrame = 1 + Int(duration / 36) % 100
            let readDuration = (props.accelerometerStart ?? props.start).timeIntervalSinceDate(props.start)
            let innerFrame = (Int(readDuration / 36) ?? 0) % 100
            ring.ringGroup.setBackgroundImageNamed("outer\(outerFrame)ring.png")
            ring.ringButton.setBackgroundImageNamed("inner\(innerFrame)ring.png")
            let text = NSDateComponentsFormatter().stringFromTimeInterval(props.duration)!
            ring.ringButton.setTitle("\(text)")
        }
    }
}
