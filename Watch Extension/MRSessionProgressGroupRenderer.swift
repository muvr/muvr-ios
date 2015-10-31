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
        if let session = MRExtensionDelegate.sharedDelegate().currentSession {
            let text = NSDateComponentsFormatter().stringFromTimeInterval(session.duration)!
            group.titleLabel.setText(session.modelId)
            group.timeLabel.setText(text)
        } else {
            group.titleLabel.setText("Idle")
            group.timeLabel.setText("")
            group.statsLabel.setText(buildDate())
        }
    }
}
