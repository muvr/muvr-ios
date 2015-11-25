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
        activate()
    }
    
    private func activate() {
        if renderer == nil {
            renderer = MRSessionProgressRingRenderer(ring: self, mode: MRSessionProgressViewType.Glance)
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
        super.didDeactivate()
    }

}
