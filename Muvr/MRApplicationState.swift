import Foundation

///
/// The initial state that can only do basic user operation like login, send token, ...
///
struct MRApplicationState {
    static var muscleGroups: [MRMuscleGroup] = MRMuscleGroupRepository.load()
    
    static var deviceToken: NSData?
    private static var loggedInStateInstance: MRLoggedInApplicationState? = nil
    
    static var loggedInState: MRLoggedInApplicationState? {
        if let x = loggedInStateInstance { return x }
        
        if let x = MRUserDefaults.getCurrentUserId() {
            MRApplicationState.loggedInStateInstance = MRLoggedInApplicationState(userId: x)
        }
        
        return MRApplicationState.loggedInStateInstance
    }
    
    // Result<MRUserId> -> Void => Result<MRLoggedInApplicationState> -> Void
    
    private static func afterLogin(g: Result<MRLoggedInApplicationState> -> Void) -> (Result<MRUserId> -> Void) {
        return { (ruid: Result<MRUserId>) in
            g(ruid.map { x in
                MRUserDefaults.setCurrentUserId(x)
                MRApplicationState.loggedInStateInstance = MRLoggedInApplicationState(userId: x)
                return MRApplicationState.loggedInStateInstance!
            })
        }
    }

    static func login(#email: String, password: String, f: Result<MRLoggedInApplicationState> -> Void) -> Void {
        MRMuvrServer.sharedInstance.apply(MRMuvrServerURLs.UserLogin(),
            body: MRMuvrServer.Body.Json(params: ["email": email, "password": password]),
            unmarshaller: MRUserId.unmarshal,
            onComplete: afterLogin(f))
    }
    
    static func register(#email: String, password: String, f: Result<MRLoggedInApplicationState> -> Void) -> Void {
        MRMuvrServer.sharedInstance.apply(MRMuvrServerURLs.UserRegister(),
            body: MRMuvrServer.Body.Json(params: ["email": email, "password": password]),
            unmarshaller: MRUserId.unmarshal,
            onComplete: afterLogin(f))
    }
    
}

///
/// Once logged in
///
struct MRLoggedInApplicationState {
    internal let userId: MRUserId
    
    init(userId: MRUserId) {
        self.userId = userId
    }
    
    func checkAccount(f: Result<Bool> -> Void) -> Void {
        f(Result.value(true))
    }
    
    func registerDeviceToken(token: NSData) -> Void {
        
    }

}

///
/// Exercising
///
struct MRExercisingApplicationState {
    let sessionId: MRSessionId
    let userId: MRUserId
    
    init(userId: MRUserId, sessionId: MRSessionId) {
        self.sessionId = sessionId
        self.userId = userId
    }
    
    func postResistanceExample(example: MRResistanceExerciseSetExample, f: Result<Void> -> Void) -> Void {        
        MRMuvrServer.sharedInstance.apply(
            MRMuvrServerURLs.ExerciseSessionResistanceExample(userId: userId, sessionId: sessionId),
            body: MRMuvrServer.Body.Json(params: example.marshal()),
            unmarshaller: constUnit(),
            onComplete: f)
    }
    
}
