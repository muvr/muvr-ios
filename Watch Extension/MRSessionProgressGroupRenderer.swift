import WatchKit

class MRSessionProgressGroupRenderer : NSObject {
    private let group: MRSessionProgressGroup
    private var timer: NSTimer?
    
    init(group: MRSessionProgressGroup) {
        self.group = group

        super.init()
        self.timer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: "update", userInfo: nil, repeats: true)
    }
    
    deinit {
        self.timer?.invalidate()
        self.timer = nil
    }
    
    func update() {
        if let session = MRExtensionDelegate.sharedDelegate().getCurrentSession() {
            let text = NSDateComponentsFormatter().stringFromTimeInterval(session.sessionDuration)!
            group.titleLabel.setText(session.title)
            group.timeLabel.setText(text)
            let batch = session.sessionStats.batchCounter
            group.statsLabel.setText("R \(batch.recorded), S \(batch.sent)")
        } else {
            group.titleLabel.setText("Idle")
            group.timeLabel.setText("")
            group.statsLabel.setText(buildDate())
        }
    }
}
