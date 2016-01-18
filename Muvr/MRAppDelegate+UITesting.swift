import UIKit
import MuvrKit

#if !RELEASE

//
// *** DO NOT RUN UI TESTS ON A DEVICE THAT CONTAINS DATA YOU WANT TO KEEP ***
//
// This code completely removes all saved in the app; the next time you start it, it will be empty.
//
// *** DO NOT RUN UI TESTS ON A DEVICE THAT CONTAINS DATA YOU WANT TO KEEP ***
//
extension MRAppDelegate  {
    
    private func generateData() {
        fatalError("Implementation is missing")
    }

    func application(application: UIApplication, willFinishLaunchingWithOptions launchOptions: [NSObject : AnyObject]?) -> Bool {
        if Process.arguments.contains("--reset-container") {
            NSLog("Reset container.")
            let fileManager = NSFileManager.defaultManager()
            [NSSearchPathDirectory.DocumentDirectory, NSSearchPathDirectory.ApplicationSupportDirectory].forEach { directory  in
                if let docs = NSSearchPathForDirectoriesInDomains(directory, NSSearchPathDomainMask.UserDomainMask, true).first {
                    (try? fileManager.contentsOfDirectoryAtPath(docs))?.forEach { file in
                        do {
                            try fileManager.removeItemAtPath("\(docs)/\(file)")
                        } catch {
                            // do nothing
                        }
                    }
                }
            }

            if Process.arguments.contains("--default-data") {
                generateData()
            }
        }
        
        return true
    }
    
}
#endif
