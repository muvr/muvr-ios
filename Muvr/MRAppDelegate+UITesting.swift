import UIKit

#if !RELEASE

//
// *** DO NOT RUN UI TESTS ON A DEVICE THAT CONTAINS DATA YOU WANT TO KEEP ***
//
// This code completely removes all saved in the app; the next time you start it, it will be empty.
//
// *** DO NOT RUN UI TESTS ON A DEVICE THAT CONTAINS DATA YOU WANT TO KEEP ***
//
extension MRAppDelegate  {

    func application(application: UIApplication, willFinishLaunchingWithOptions launchOptions: [NSObject : AnyObject]?) -> Bool {
        if Process.arguments.contains("--reset-container") {
            NSLog("Reset container.")
            if let docs = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true).first {
                try! NSFileManager.defaultManager().removeItemAtPath(docs)
                try! NSFileManager.defaultManager().createDirectoryAtPath(docs, withIntermediateDirectories: false, attributes: nil)
            }
        }

        // TODO: some form of XPC
        let port: mach_port_t = 9990
        var header: mach_msg_header_t = mach_msg_header_t()
        header.msgh_remote_port = port
        let error = mach_msg_receive(&header)
        if (error == MACH_MSG_SUCCESS) {
            print(":(")
        } else {
            print(":)")
        }

        return true
    }
    
}
#endif
