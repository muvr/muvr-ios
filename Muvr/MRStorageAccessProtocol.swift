import Foundation

///
/// Protocol to access remote files in the cloud
/// Note: All continuation block are called on background threads
///       Don't forget to dispatch to the main queue for UI changes
///
protocol MRStorageAccessProtocol {
    
    ///
    /// upload the given ``data`` into remote ``path``
    ///
    func uploadFile(path: String, data: NSData, continuation: () -> Void)
    ///
    /// upload the given ``data`` into remote ``url``
    ///
    func uploadFile(url: NSURL, data: NSData, continuation: () -> Void)
    ///
    /// download the remote file pointed by ``path``
    ///
    func downloadFile(path: String, continuation: NSURL? -> Void)
    ///
    /// download the remote file pointed by ``url``
    ///
    func downloadFile(url: NSURL, continuation: NSURL? -> Void)
    ///
    /// list the remote files located at ``path``
    ///
    func listFiles(path: String, continuation: [NSURL]? -> Void)
    ///
    /// list the remote files located at ``url``
    ///
    func listFiles(url: NSURL, continuation: [NSURL]? -> Void)
    
    
}
