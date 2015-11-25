import WatchKit
import MuvrKit

class MRSessionProgressRingRenderer : NSObject {
    private let ring: MRSessionProgressRing
    private let health: MRSessionHealth?
    private var timer: NSTimer?
    
    init(ring: MRSessionProgressRing, health: MRSessionHealth?) {
        self.ring = ring
        self.health = health
        super.init()
        NSLog("Init Muvr watch view")
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
            displayCurrentSession(session, props: props)
        } else if let (session, props) = sd.pendingSession {
            displayPendingSession(session, props: props)
        }
        else {
            displayIdle()
        }
    }
    
    private func displayCurrentSession(session: MKExerciseSession, props: MKExerciseSessionProperties) {
        let sd = MRExtensionDelegate.sharedDelegate()
        let expectedDuration = 60
        let duration = props.duration
        let outerFrame = 1 + Int(100 * duration / Double(expectedDuration * 60)) % 100
        let readDuration = (props.accelerometerStart ?? props.start).timeIntervalSinceDate(props.start)
        let innerFrame = (Int(100 * readDuration / Double(expectedDuration * 60)) ?? 0) % 100
        let time = NSDateComponentsFormatter().stringFromTimeInterval(props.duration)!
        let sent = NSByteCountFormatter().stringFromByteCount(Int64(readDuration * 600))
        let total = NSByteCountFormatter().stringFromByteCount(Int64(duration * 600))
        
        ring.timeLabel.setText("\(time)") // elapsed time
        ring.ringLabel.setText("\(total)\n\(sent)") // amount of sensor data
        ring.outerRing.setBackgroundImageNamed("outer\(outerFrame)ring.png") // elapsed time ring
        ring.innerRing.setBackgroundImageNamed("inner\(innerFrame)ring.png") // data sent ring
        if let health = health {
            ring.titleLabel.setText("\(session.modelId)") // title
            ring.sessionLabel.setText("") // session label not used
            if let heartrate = sd.heartrate {
                health.heartGroup.setBackgroundImageNamed("heart") // heart image
                health.heartLabel.setText("\(Int(heartrate))") // current heartrate value
            }
            if let energy = sd.energyBurned {
                health.energyGroup.setBackgroundImageNamed("blue") // energy circle icon
                health.energyLabel.setText("\(Int(energy))") // total energy burnt
            }
        } else {
            ring.titleLabel.setText("Muvr - \(session.modelId)") // title on glance
            ring.sessionLabel.setText("\(sd.sessionsCount) sessions") // number of pending (incomplete) session
        }
    }
    
    private func displayPendingSession(session: MKExerciseSession, props: MKExerciseSessionProperties) {
        let sd = MRExtensionDelegate.sharedDelegate()
        let duration = props.duration
        let readDuration = (props.accelerometerStart ?? props.start).timeIntervalSinceDate(props.start)
        let innerFrame = (Int(100 * readDuration / duration) ?? 0) % 100
        let time = NSDateComponentsFormatter().stringFromTimeInterval(props.duration)!
        ring.titleLabel.setText("Muvr - \(session.modelId)") // title on glance
        ring.timeLabel.setText("\(time)") // session duration
        ring.ringLabel.setText("\(innerFrame)%") // percent of data sent
        ring.outerRing.setBackgroundImageNamed("outer100ring.png") // elapsed time is always 100%
        ring.innerRing.setBackgroundImageNamed("inner\(innerFrame)ring.png") // percent of sent data
        ring.sessionLabel.setText("\(sd.sessionsCount) sessions") // number of pending (incomplete) sessions
    }
    
    private func displayIdle() {
        ring.titleLabel.setText("Muvr")
        ring.timeLabel.setText("Idle")
        ring.ringLabel.setText("")
        ring.outerRing.setBackgroundImageNamed("outer0ring.png")
        ring.innerRing.setBackgroundImageNamed("inner0ring.png")
        ring.sessionLabel.setText("No sessions")
    }
}
