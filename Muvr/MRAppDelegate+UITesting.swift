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
    
    func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [NSObject : AnyObject]?) -> Bool {
        if Process.argc > 0 && Process.arguments.contains("--reset-container") {
            NSLog("Reset container.")
            let fileManager = FileManager.default()
            [FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDirectory.applicationSupportDirectory].forEach { directory  in
                if let docs = NSSearchPathForDirectoriesInDomains(directory, FileManager.SearchPathDomainMask.userDomainMask, true).first {
                    (try? fileManager.contentsOfDirectory(atPath: docs))?.forEach { file in
                        do {
                            try fileManager.removeItem(atPath: "\(docs)/\(file)")
                        } catch {
                            // do nothing
                        }
                    }
                }
            }

        }
        return true
    }
    
}
#endif
