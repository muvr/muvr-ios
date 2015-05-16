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
        let id = NSUUID()
        let session = MRResistanceExerciseSession(startDate: NSDate(), properties: properties)
        MRDataModel.MRResistanceExerciseSessionDataModel.insert(id, session: session)
        return MRExercisingApplicationState(userId: userId, sessionId: id, session: session)
    }
    
    ///
    /// Removes an existing session locally and on the server
    ///
    func deleteSession(id: NSUUID) -> Void {
        MRDataModel.MRResistanceExerciseSessionDataModel.delete(id)
    }

    ///
    /// Returns the 100 most recent resistance exercise sessions, ordered by descending startDate
    ///
    func getResistanceExerciseSessions() -> [MRResistanceExerciseSession] {
        return MRDataModel.MRResistanceExerciseSessionDataModel.findAll(limit: 100)
    }
    
    ///
    /// Returns the MRResistanceExerciseSessionDetail that happened on the given day (i.e. from midnight to midnight)
    ///
    func getResistanceExerciseSessionDetails(on date: NSDate) -> [MRResistanceExerciseSessionDetail] {
        return MRDataModel.MRResistanceExerciseSessionDataModel.find(on: date)
    }
    
    ///
    /// Returns ``MRResistanceExercisePlan``s that should happen on the given ``date``
    ///
    func getSimpleResistanceExercisePlansOn(on date: NSDate) -> [MRResistanceExercisePlan] {
        if isAnonymous {
            return MRDataModel.MRResistanceExercisePlanDataModel.defaultPlans
        }
        return MRDataModel.MRResistanceExercisePlanDataModel.defaultPlans
    }
    
}

///
/// Exercising
///
struct MRExercisingApplicationState {
    let sessionId: MRSessionId
    let userId: MRUserId
    let session: MRResistanceExerciseSession
    
    init(userId: MRUserId, sessionId: MRSessionId, session: MRResistanceExerciseSession) {
        self.sessionId = sessionId
        self.userId = userId
        self.session = session
    }
    
    func end(deviations: [MRExercisePlanDeviation]) -> Void {
        deviations.forEach { MRDataModel.MRResistanceExerciseSessionDataModel.insertExercisePlanDeviation(NSUUID(), sessionId: self.sessionId, deviation: $0) }
    }
    
    func postResistanceExample(example: MRResistanceExerciseSetExample) -> Void {
        let id = NSUUID()
        
        if let set = example.correct {
            MRDataModel.MRResistanceExerciseSessionDataModel.insertResistanceExerciseSet(id, sessionId: sessionId, set: set)
        }
        MRDataModel.MRResistanceExerciseSessionDataModel.insertResistanceExerciseSetExample(id, sessionId: sessionId, example: example)

        #if true
        MRMuvrServer.sharedInstance.apply(
            MRMuvrServerURLs.ExerciseSessionResistanceExample(userId: userId, sessionId: sessionId),
            body: MRMuvrServer.Body.Json(params: example.marshal()),
            unmarshaller: constUnit(),
            onComplete: constUnit())
        #endif
    }
    
}
