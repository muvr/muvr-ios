import MuvrKit
@testable import Muvr

class MRLocalStorageAccess: MRCloudStorageAccessProtocol {
    
    var dir: NSURL {
        let url = NSURL(fileURLWithPath: NSTemporaryDirectory()).URLByAppendingPathComponent("muvrtest")
        try! NSFileManager.defaultManager().createDirectoryAtURL(url, withIntermediateDirectories: true, attributes: nil)
        return url
    }
    
    private(set) var uploads: [NSURL] = [NSURL]()
    private(set) var downloads: [NSURL] = [NSURL]()
    
    func reset() {
        let fileManager = NSFileManager.defaultManager()
        uploads.forEach { url in
            do {
                try fileManager.removeItemAtURL(url)
            } catch { }
        }
        uploads = [NSURL]()
        downloads = [NSURL]()
    }

    ///
    /// list the remote files located at ``path``
    ///
    func listFiles(path: String, continuation: [NSURL]? -> Void) {
        listFiles(dir.URLByAppendingPathComponent(path), continuation: continuation)
    }
    ///
    /// list the remote files located at ``url``
    ///
    func listFiles(url: NSURL, continuation: [NSURL]? -> Void) {
        continuation(uploads)
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
    
    ///
    /// download the remote file pointed by ``path``
    ///
    func downloadFile(path: String, continuation: NSURL? -> Void) {
        downloadFile(dir.URLByAppendingPathComponent(path), continuation: continuation)
    }
    ///
    /// download the remote file pointed by ``url``
    ///
    func downloadFile(url: NSURL, continuation: NSURL? -> Void) {
        // do nothing
        downloads.append(url)
        continuation(url)
    }
    
}
