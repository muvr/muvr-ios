import WatchKit
import Foundation
import WatchConnectivity

class InterfaceController: WKInterfaceController, WCSessionDelegate {

    @IBAction func sendData() {
        if WCSession.isSupported() {
            WCSession.defaultSession().delegate = self
            WCSession.defaultSession().activateSession()
            let x: NSString = "foofaff"
            let d = x.dataUsingEncoding(NSASCIIStringEncoding)!
            WCSession.defaultSession().sendMessageData(d, replyHandler: { _ -> Void in
                    // noop
                    print(":)")
                }, errorHandler: { e -> Void in
                    // noop
                    print(":( \(e)")
            })
        }
    }
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
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
