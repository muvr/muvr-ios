import Foundation
import Alamofire

///
/// The request to the Lift server-side code
///
struct MRMuvrServerRequest {
    var path: String
    var method: Alamofire.Method
    
    init(path: String, method: Alamofire.Method) {
        self.path = path
        self.method = method
    }
    
}

///
/// Defines mechanism to convert a request to LiftServerRequest
///
protocol MRMuvrServerRequestConvertible {
    var Request: MRMuvrServerRequest { get }
}

///
/// The Lift server URLs and request data mappers
///
enum MRMuvrServerURLs : MRMuvrServerRequestConvertible {
    
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
    var Request: MRMuvrServerRequest {
        get {
            let r: MRMuvrServerRequest = {
                switch self {
                case let .exerciseSessionPayload: return MRMuvrServerRequest(path: "/exerciseSession/payload", method: Method.POST)
                }
                }()
            
            return r
        }
    }
}

