import Foundation

protocol MRCloudStorageAccessProtocol {

    ///
    /// list the remote files located at ``path``
    ///
    func listFiles(path: String, continuation: [NSURL]? -> Void)
    ///
    /// list the remote files located at ``url``
    ///
    func listFiles(url: NSURL, continuation: [NSURL]? -> Void)
    
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
    func downloadFile(path: String, continuation: NSData? -> Void)
    ///
    /// download the remote file pointed by ``url``
    ///
    func downloadFile(url: NSURL, continuation: NSData? -> Void)
    
}
