import Foundation

///
/// The request to the Lift server-side code
///
struct MuvrServerRequest {
    var path: String
    var method: Method
    
    init(path: String, method: Method) {
        self.path = path
        self.method = method
    }
    
}

///
/// Defines mechanism to convert a request to LiftServerRequest
///
protocol MuvrServerRequestConvertible {
    var Request: MuvrServerRequest { get }
}

///
/// The Lift server URLs and request data mappers
///
enum MuvrServerURLs : MuvrServerRequestConvertible {
    
    ///
    /// Register the user
    ///
    case exerciseSessionPayload()
    
    private struct Format {
        private static let simpleDateFormatter: NSDateFormatter = {
            let dateFormatter = NSDateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            return dateFormatter
            }()
        
        static func simpleDate(date: NSDate) -> String {
            return simpleDateFormatter.stringFromDate(date)
        }
        
    }
    
    // MARK: URLStringConvertible
    var Request: MuvrServerRequest {
        get {
            let r: MuvrServerRequest = {
                switch self {
                case let .exerciseSessionPayload: return MuvrServerRequest(path: "/exerciseSession/payload", method: Method.POST)
                }
                }()
            
            return r
        }
    }
}

