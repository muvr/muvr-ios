import Foundation


///
/// Returns the configured Lift server URL, or a default value. The value is set in the
/// settings bundle for the application. See ``Settings.bundle``.
///
struct MuvrUserDefaults {
    static var muvrServerUrl: String {
        get {
            if let url = NSUserDefaults.standardUserDefaults().stringForKey("muvrServerUrl") {
                return url
            } else {
                return "http://127.0.0.1:8089"
            }
        }
    }
}