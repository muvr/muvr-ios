import Foundation
import SQLite

///
/// The initial state that can only do basic user operation like login, send token, ...
///
struct MRApplicationState {
    static var muscleGroups: [MRMuscleGroup] = MRMuscleGroupRepository.load()
    
    static var deviceToken: NSData?
    
    static let anonymousUserId: MRUserId = UIDevice.currentDevice().identifierForVendor
    
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
    
    static func skip(f: Result<MRLoggedInApplicationState> -> Void) -> Void {
        MRApplicationState.loggedInStateInstance = MRLoggedInApplicationState(userId: anonymousUserId)
        f(Result.value(MRApplicationState.loggedInStateInstance!))
    }
    
}

///
/// Once logged in
///
struct MRLoggedInApplicationState {
    internal let userId: MRUserId
    internal let isAnonymous: Bool
    
    init(userId: MRUserId) {
        self.userId = userId
        self.isAnonymous = userId == MRApplicationState.anonymousUserId
    }
    
    func checkAccount(f: Result<Bool> -> Void) -> Void {
        f(Result.value(true))
        // TODO: Implement me
    }
    
    func registerDeviceToken(token: NSData) -> Void {
        // TODO: Implement me
    }
    
    ///
    /// Starts a resistance exercise session with the given properties
    ///
    func startSession(properties: MRResistanceExerciseSessionProperties) -> MRExercisingApplicationState {
        let sessionId = MRSessionId()
        let session = MRResistanceExerciseSession(startDate: NSDate(), properties: properties)
        MRDataModel.resistanceExerciseSessions.insert(
            MRDataModel.MRResistanceExerciseSessionDataModel.id <- sessionId,
            MRDataModel.MRResistanceExerciseSessionDataModel.timestamp <- session.startDate,
            MRDataModel.MRResistanceExerciseSessionDataModel.json <- JSON(session.marshal()))
        return MRExercisingApplicationState(userId: userId, sessionId: sessionId)
    }
    
    ///
    /// Returns the 100 most recent resistance exercise sessions, ordered by descending startDate
    ///
    func getResistanceExerciseSessions() -> [MRResistanceExerciseSession] {
        return MRDataModel.MRResistanceExerciseSessionDataModel.findAll(limit: 100)
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
    
    func postResistanceExample(example: MRResistanceExerciseSetExample) -> Void {
        let id = NSUUID()
        
        MRDataModel.resistanceExerciseSets.insert(
            MRDataModel.MRResistanceExerciseSetDataModel.id <- id,
            MRDataModel.MRResistanceExerciseSetDataModel.timestamp <- NSDate(),
            MRDataModel.MRResistanceExerciseSetDataModel.sessionId <- sessionId,
            MRDataModel.MRResistanceExerciseSetDataModel.json <- JSON(example.marshal())
        )
        
        MRMuvrServer.sharedInstance.apply(
            MRMuvrServerURLs.ExerciseSessionResistanceExample(userId: userId, sessionId: sessionId),
            body: MRMuvrServer.Body.Json(params: example.marshal()),
            unmarshaller: constUnit(),
            onComplete: constUnit())
    }
    
}
