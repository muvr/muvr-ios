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
/// The Muvr server URLs and request data mappers
///
enum MRMuvrServerURLs : MRMuvrServerRequestConvertible {
    
    //case ExerciseSessionResistanceExample(userId: MRUserId, sessionId: MRSessionId)
    
    case SubmitEntireResistanceExerciseSession(userId: MRUserId, sessionId: MRSessionId)
    
    /// Get user public profile
    case GetPublicProfile(userId: MRUserId)
    /// Set user public profile
    case SetPublicProfile(userId: MRUserId)
    
    /// Set profile image
    case SetProfileImage(userId: MRUserId)
    /// Get profile image
    case GetProfileImage(userId: MRUserId)
    
    /// User login
    case UserLogin()
    /// User registration
    case UserRegister()
    
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
                case .SubmitEntireResistanceExerciseSession(let user, let session): return MRMuvrServerRequest(path: "/exercise/\(user.UUIDString)/resistance", method: Method.POST)
                case .UserLogin: return MRMuvrServerRequest(path: "/user", method: Method.PUT)
                case .UserRegister: return MRMuvrServerRequest(path: "/user", method: Method.POST)
                case .GetPublicProfile(let user): return MRMuvrServerRequest(path: "/user/\(user.UUIDString)", method: Method.GET)
                case .SetPublicProfile(let user): return MRMuvrServerRequest(path: "/user/\(user.UUIDString)", method: Method.POST)
                case .SetProfileImage(let user): return MRMuvrServerRequest(path: "/user/\(user.UUIDString)/image", method: Method.POST)
                case .GetProfileImage(let user): return MRMuvrServerRequest(path: "/user/\(user.UUIDString)/image", method: Method.GET)
                }
                }()
            
            return r
        }
    }
}

