import Foundation
import MuvrKit

///
/// The initial state that can only do basic user operation like login, send token, ...
///
struct MRApplicationState {
    
    static var exerciseModels: [MKExerciseModel] {
        return MRDataModel.MRExerciseModelDataModel.get()
    }
    
    static var deviceToken: NSData?
    
    static let anonymousUserId: MRUserId = UIDevice.currentDevice().identifierForVendor!
    
    private static var loggedInStateInstance: MRLoggedInApplicationState? = nil
    
    ///
    /// Returns the currently logged-in state
    ///
    static var loggedInState: MRLoggedInApplicationState? {
        if let x = loggedInStateInstance { return x }
        
        if let x = MRUserDefaults.getCurrentUserId() {
            MRApplicationState.loggedInStateInstance = MRLoggedInApplicationState(userId: x)
        }
        
        return MRApplicationState.loggedInStateInstance
    }
    
    /// Result<MRUserId> -> Void => Result<MRLoggedInApplicationState> -> Void
    /// performs operation after successful login
    private static func afterLogin(g: Result<MRLoggedInApplicationState> -> Void) -> (Result<MRUserId> -> Void) {
        return { (ruid: Result<MRUserId>) in
            g(ruid.map { x in
                MRUserDefaults.setCurrentUserId(x)
                MRApplicationState.loggedInStateInstance = MRLoggedInApplicationState(userId: x)
                return MRApplicationState.loggedInStateInstance!
            })
        }
    }

    /// Logs in the user with the given email and password
    static func login(email email: String, password: String, f: Result<MRLoggedInApplicationState> -> Void) -> Void {
        MRMuvrServer.sharedInstance.apply(MRMuvrServerURLs.UserLogin(),
            body: MRMuvrServer.Body.Json(params: ["email": email, "password": password]),
            unmarshaller: MRUserId.unmarshal,
            onComplete: afterLogin(f))
    }

    /// Registers a new user with the given username and password
    static func register(email email: String, password: String, f: Result<MRLoggedInApplicationState> -> Void) -> Void {
        MRMuvrServer.sharedInstance.apply(MRMuvrServerURLs.UserRegister(),
            body: MRMuvrServer.Body.Json(params: ["email": email, "password": password]),
            unmarshaller: MRUserId.unmarshal,
            onComplete: afterLogin(f))
    }

    /// Skips the login operation
    static func skip(f: Result<MRLoggedInApplicationState> -> Void) -> Void {
        MRApplicationState.loggedInStateInstance = MRLoggedInApplicationState(userId: anonymousUserId)
        f(Result.value(MRApplicationState.loggedInStateInstance!))
    }
    
    /// Removes cached training data
    static func clearTrainingData() {
        /*
        let paths = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)
        let path = (paths.first as! String)
        for file in NSFileManager.defaultManager().contentsOfDirectoryAtPath(path, error: nil)! as! [String] {
            if file.pathExtension == "raw" {
                NSFileManager.defaultManager().removeItemAtPath(path.stringByAppendingPathComponent(file), error: nil)
            }
        }
        */
        MRDataModel.MRResistanceExerciseSessionDataModel.deleteAll()
    }
    
}
