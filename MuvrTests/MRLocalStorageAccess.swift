import MuvrKit
@testable import Muvr

class MRLocalStorageAccess: MRStorageAccessProtocol {
    
    var dir: NSURL {
        let url = NSURL(fileURLWithPath: NSTemporaryDirectory()).URLByAppendingPathComponent("muvrtest")
        try! NSFileManager.defaultManager().createDirectoryAtURL(url, withIntermediateDirectories: true, attributes: nil)
        return url
    }
    
    private(set) var uploads: [NSURL] = [NSURL]()
    
    func reset() {
        let fileManager = NSFileManager.defaultManager()
        uploads.forEach { url in
            do {
                try fileManager.removeItemAtURL(url)
            } catch { }
        }
        uploads = [NSURL]()
        
    }
    
    ///
    /// upload the given ``data`` into remote ``path``
    ///
    func uploadFile(path: String, data: NSData, continuation: () -> Void) {
        uploadFile(dir.URLByAppendingPathComponent(path), data: data, continuation: continuation)
    }
    ///
    /// upload the given ``data`` into remote ``url``
    ///
    func uploadFile(url: NSURL, data: NSData, continuation: () -> Void) {
        data.writeToURL(url, atomically: true)
        uploads.append(url)
        continuation()
    }
    
}
