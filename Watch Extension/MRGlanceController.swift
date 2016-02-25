import WatchKit
import Foundation
import HealthKit

class MRGlanceController: WKInterfaceController, MRSessionProgressRing {
    @IBOutlet weak var titleLabel: WKInterfaceLabel!
    @IBOutlet weak var timeLabel: WKInterfaceLabel!
    @IBOutlet weak var ringLabel: WKInterfaceLabel!
    @IBOutlet weak var innerRing: WKInterfaceGroup!
    @IBOutlet weak var outerRing: WKInterfaceGroup!
    @IBOutlet weak var sessionLabel: WKInterfaceLabel!
    
    private var renderer: MRSessionProgressRingRenderer?
    
    override func willActivate() {
        super.willActivate()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(MRGlanceController.sessionDidChange(_:)), name: MRNotifications.CurrentSessionDidStart.rawValue, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(MRGlanceController.sessionDidChange(_:)), name: MRNotifications.CurrentSessionDidEnd.rawValue, object: nil)
        activate()
    }
    
    private func activate() {
        if renderer == nil {
            renderer = MRSessionProgressRingRenderer(ring: self, health: nil)
        }
        MRExtensionDelegate.sharedDelegate().applicationDidBecomeActive()
    }
    
    override func didAppear() {
        if renderer == nil {
            activate()
        }
    }

    override func didDeactivate() {
        renderer?.deactivate()
        renderer = nil
        NSNotificationCenter.defaultCenter().removeObserver(self)
        super.didDeactivate()
    }
    
    /// callback function invoked when session is started/ended on the phone
    internal func sessionDidChange(notification: NSNotification) {
        renderer?.update()
    }

}
