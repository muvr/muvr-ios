import WatchKit
import Foundation
import WatchConnectivity
import SensorData

class InterfaceController: WKInterfaceController, WCSessionDelegate {
    private var timer: NSTimer?

    @IBAction func sendData() {
        if let t = timer {
            t.invalidate()
            timer = nil
        } else if WCSession.isSupported() {
            timer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: "tick", userInfo: nil, repeats: true)
            WCSession.defaultSession().delegate = self
            WCSession.defaultSession().activateSession()
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
    
    func tick() {
        let d = NSMutableData(length: 650)!
        WCSession.defaultSession().sendMessageData(d,
            replyHandler: { _ -> Void in
                // noop
                print(":)")
            }, errorHandler: { e -> Void in
                // noop
                print(":( \(e)")
        })
    }

}
