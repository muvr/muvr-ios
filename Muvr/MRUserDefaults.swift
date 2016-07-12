import Foundation


///
/// Returns the configured Muvr server URL, or a default value. The value is set in the
/// settings bundle for the application. See ``Settings.bundle``.
///
struct MRUserDefaults {
    
    ///
    /// Returns ``true`` if the application is being launched to run tests
    ///
    static var isRunningTests: Bool {
        let environment = ProcessInfo.processInfo.environment
        if let injectBundle = environment["XCInjectBundle"] as String? {
            return URL(fileURLWithPath: injectBundle).pathExtension ?? "" == "xctest"
        }
        return false
    }
    
}
