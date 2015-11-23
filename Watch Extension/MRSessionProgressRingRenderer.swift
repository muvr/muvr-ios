import WatchKit

enum MRSessionProgressViewType: String {
    case App
    case Glance
}

class MRSessionProgressRingRenderer : NSObject {
    private let ring: MRSessionProgressRing
    private var timer: NSTimer?
    private var mode: MRSessionProgressViewType
    
    init(ring: MRSessionProgressRing, mode: MRSessionProgressViewType) {
        self.ring = ring
        self.mode = mode
        super.init()
        NSLog("Init progress view in \(mode)")
        self.timer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: "update", userInfo: nil, repeats: true)
    }
    
    deinit {
        self.deactivate()
    }
    
    func deactivate() {
        self.timer?.invalidate()
        self.timer = nil
    }
    
    func update() {
        let sd = MRExtensionDelegate.sharedDelegate()
        sd.applicationDidBecomeActive()
        if let (session, props) = sd.currentSession {
            let expectedDuration = 60
            let duration = props.duration
            let outerFrame = 1 + Int(100 * duration / Double(expectedDuration * 60)) % 100
            let readDuration = (props.accelerometerStart ?? props.start).timeIntervalSinceDate(props.start)
            let innerFrame = (Int(100 * readDuration / Double(expectedDuration * 60)) ?? 0) % 100
            let time = NSDateComponentsFormatter().stringFromTimeInterval(props.duration)!
            let sent = Int(readDuration * 600 / 1000) // kb
            let total = Int(duration * 600 / 1000) // kb
            if mode == MRSessionProgressViewType.Glance {
                ring.titleLabel.setText("Muvr - \(session.modelId)")
                ring.timeLabel.setText("\(time)")
                ring.ringLabel.setText("\(total)kb\n\(sent)kb")
                ring.sessionLabel.setText("\(sd.sessionsCount) sessions")
            } else {
                ring.titleLabel.setText("\(session.modelId)")
                ring.timeLabel.setText("")
                ring.ringLabel.setText("\(time)\n\(total)kb\n\(sent)kb")
                ring.sessionLabel.setText("")
            }
            ring.outerRing.setBackgroundImageNamed("outer\(outerFrame)ring.png")
            ring.innerRing.setBackgroundImageNamed("inner\(innerFrame)ring.png")
        } else if let (session, props) = sd.pendingSession {
            let duration = props.duration
            let readDuration = (props.accelerometerStart ?? props.start).timeIntervalSinceDate(props.start)
            let innerFrame = (Int(100 * readDuration / duration) ?? 0) % 100
            let time = NSDateComponentsFormatter().stringFromTimeInterval(props.duration)!
            ring.titleLabel.setText("Muvr - \(session.modelId)")
            ring.timeLabel.setText("\(time)")
            ring.ringLabel.setText("sync \(innerFrame)%")
            ring.outerRing.setBackgroundImageNamed("outer100ring.png")
            ring.innerRing.setBackgroundImageNamed("inner\(innerFrame)ring.png")
            ring.sessionLabel.setText("\(sd.sessionsCount) sessions")
        }
        else {
            ring.titleLabel.setText("Muvr")
            ring.timeLabel.setText("Idle")
            ring.ringLabel.setText("")
            ring.outerRing.setBackgroundImageNamed("outer0ring.png")
            ring.innerRing.setBackgroundImageNamed("inner0ring.png")
            ring.sessionLabel.setText("No sessions")
        }
    }
}
