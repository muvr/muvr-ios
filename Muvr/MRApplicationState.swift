import Foundation
import SQLite

///
/// The initial state that can only do basic user operation like login, send token, ...
///
struct MRApplicationState {
    
    static var muscleGroups: [MRMuscleGroup] {
        return MRDataModel.MRMuscleGroupDataModel.get(NSLocale.currentLocale())
    }
    
    static var exercises: [MRExercise] {
        return MRDataModel.MRExerciseDataModel.get(NSLocale.currentLocale())
    }
    
    static func joinMuscleGroups(ids: [MRMuscleGroupId]) -> String {
        return ", ".join(muscleGroups.flatMap { (mg: MRMuscleGroup) -> String? in
            if (ids.exists { $0 == mg.id }) { return mg.title }
            return nil
        })
    }
    
    static var deviceToken: NSData?
    
    static let anonymousUserId: MRUserId = UIDevice.currentDevice().identifierForVendor
    
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
    static func login(#email: String, password: String, f: Result<MRLoggedInApplicationState> -> Void) -> Void {
        MRMuvrServer.sharedInstance.apply(MRMuvrServerURLs.UserLogin(),
            body: MRMuvrServer.Body.Json(params: ["email": email, "password": password]),
            unmarshaller: MRUserId.unmarshal,
            onComplete: afterLogin(f))
    }

    /// Registers a new user with the given username and password
    static func register(#email: String, password: String, f: Result<MRLoggedInApplicationState> -> Void) -> Void {
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
    
}
