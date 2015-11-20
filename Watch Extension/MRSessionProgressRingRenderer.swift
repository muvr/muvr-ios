import WatchKit

class MRSessionProgressRingRenderer : NSObject {
    private let ring: MRSessionProgressRing
    private var timer: NSTimer?
    private var expectedDuration: Int // minutes
    
    init(ring: MRSessionProgressRing, duration: Int) {
        self.ring = ring
        self.expectedDuration = duration
        super.init()
        self.timer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: "update", userInfo: nil, repeats: true)
        update()
    }
    
    deinit {
        self.deactivate()
    }
    
    func deactivate() {
        self.timer?.invalidate()
        self.timer = nil
    }
    
    func setExpectedDuration(duration: Int) {
        expectedDuration = duration
    }
    
    func update() {
        if let (_, props) = MRExtensionDelegate.sharedDelegate().currentSession {
            let duration = props.duration
            let outerFrame = 1 + Int(100 * duration / Double(expectedDuration * 60)) % 100
            let readDuration = (props.accelerometerStart ?? props.start).timeIntervalSinceDate(props.start)
            let innerFrame = (Int(100 * readDuration / Double(expectedDuration * 60)) ?? 0) % 100
            ring.ringGroup.setBackgroundImageNamed("outer\(outerFrame)ring.png")
            ring.ringButton.setBackgroundImageNamed("inner\(innerFrame)ring.png")
            let time = NSDateComponentsFormatter().stringFromTimeInterval(props.duration)!
            let sent = Int(readDuration * 600 / 1000) // kb
            let total = Int(duration * 600 / 1000) // kb
            ring.ringButton.setTitle("\(time)\n\(sent)/\(total)kb")
        }
    }
}
