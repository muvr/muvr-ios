import WatchKit
import Foundation

class MRGlanceController: WKInterfaceController {
    @IBOutlet weak var modelLabel: WKInterfaceLabel!
    @IBOutlet weak var intensityLabel: WKInterfaceLabel!

    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        
        // Configure interface objects here.
        if let session = MRExtensionDelegate.sharedDelegate().getCurrentSession() {
            modelLabel.setText(session.modelTitle)
            intensityLabel.setText(session.intensityTitle)
        }
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

}
