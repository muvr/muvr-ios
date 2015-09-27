import WatchKit
import WatchConnectivity

class ExtensionDelegate : NSObject, WKExtensionDelegate, WCSessionDelegate {
    private var state: MRApplicationState?
    
    static func sharedDelegate() -> ExtensionDelegate {
        return WKExtension.sharedExtension().delegate! as! ExtensionDelegate
    }

    func applicationDidFinishLaunching() {
        state = MRApplicationState()
    }

    func applicationDidBecomeActive() {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillResignActive() {
        state = nil
    }

}
