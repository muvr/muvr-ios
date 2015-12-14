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
    
}
