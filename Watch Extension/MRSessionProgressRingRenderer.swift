import WatchKit
import MuvrKit

class MRSessionProgressRingRenderer : NSObject {
    private let ring: MRSessionProgressRing
    private let health: MRSessionHealth?
    private var timer: Timer?
    
    init(ring: MRSessionProgressRing, health: MRSessionHealth?) {
        self.ring = ring
        self.health = health
        super.init()
        NSLog("Init Muvr watch view")
        update()
        self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(MRSessionProgressRingRenderer.update), userInfo: nil, repeats: true)
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
        if let (session, props) = sd.currentSession {
            displayCurrentSession(session, props: props)
        } else if let (session, props) = sd.pendingSession {
            displayPendingSession(session, props: props)
        }
        else {
            displayIdle()
        }
        sd.applicationDidBecomeActive()
    }
    
    func reset() {
        ring.timeLabel.setText("") // elapsed time
        ring.ringLabel.setText("") // amount of sensor data
        ring.outerRing.setBackgroundImageNamed("outer0ring.png") // elapsed time ring
        ring.innerRing.setBackgroundImageNamed("inner0ring.png") // data sent ring
        ring.titleLabel.setText("") // title
        ring.sessionLabel.setText("") // session label
        health?.heartGroup.setBackgroundImage(nil) // remove heart image
        health?.heartLabel.setText("") // heartrate value
        health?.energyGroup.setBackgroundImage(nil) // remove energy circle icon
        health?.energyLabel.setText("") // energy burned value
    }
    
    private func displayCurrentSession(_ session: MKExerciseSession, props: MKExerciseSessionProperties) {
        let sd = MRExtensionDelegate.sharedDelegate()
        let expectedDuration = 60
        let duration = props.duration
        let outerFrame = 1 + Int(100 * duration / Double(expectedDuration * 60)) % 100
        let readDuration = (props.accelerometerStart ?? props.start).timeIntervalSince(props.start)
        let innerFrame = (Int(100 * readDuration / Double(expectedDuration * 60)) ?? 0) % 100
        let time = DateComponentsFormatter().string(from: props.duration)!
        let sent = ByteCountFormatter().stringFromByteCount(Int64(readDuration * 600))
        let total = ByteCountFormatter().stringFromByteCount(Int64(duration * 600))
        
        ring.timeLabel.setText("\(time)") // elapsed time
        ring.ringLabel.setText("\(total)\n\(sent)") // amount of sensor data
        ring.outerRing.setBackgroundImageNamed("outer\(outerFrame)ring.png") // elapsed time ring
        ring.innerRing.setBackgroundImageNamed("inner\(innerFrame)ring.png") // data sent ring
        if let health = health {
            ring.titleLabel.setText("\(session.exerciseType.title)") // title
            ring.sessionLabel.setText("") // session label not used
            if let heartrate = sd.heartrate {
                health.heartGroup.setBackgroundImageNamed("heart") // heart image
                health.heartLabel.setText("\(Int(heartrate))") // current heartrate value
            } else {
                health.heartGroup.setBackgroundImage(nil) // remove heart image
                health.heartLabel.setText("")
            }
            if let energy = sd.energyBurned where energy >= 1 {
                health.energyGroup.setBackgroundImageNamed("blue") // energy circle icon
                health.energyLabel.setText("\(Int(energy))") // total energy burnt
            } else {
                health.energyGroup.setBackgroundImage(nil) // remove energy circle icon
                health.energyLabel.setText("")
            }
        } else {
            ring.titleLabel.setText("Muvr - \(session.exerciseType.title)") // title on glance
            ring.sessionLabel.setText("\(sd.sessionsCount) sessions") // number of pending (incomplete) session
        }
    }
    
    private func displayPendingSession(_ session: MKExerciseSession, props: MKExerciseSessionProperties) {
        let sd = MRExtensionDelegate.sharedDelegate()
        let duration = props.duration
        let readDuration = (props.accelerometerStart ?? props.start).timeIntervalSince(props.start)
        let innerFrame = (Int(100 * readDuration / duration) ?? 0) % 100
        let time = DateComponentsFormatter().string(from: props.duration)!
        ring.titleLabel.setText("Muvr - \(session.exerciseType.title)") // title on glance
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
