import Foundation

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
    
    
    /// MARK: Profile functions
    func getPublicProfile(f: Result<MRPublicProfile?> -> Void) -> Void {
        MRMuvrServer.sharedInstance.apply(MRMuvrServerURLs.GetPublicProfile(userId: userId), unmarshaller: MRPublicProfile.unmarshal, onComplete: f)
    }
    
    func setPublicProfile(profile: MRPublicProfile, f: Result<Void> -> Void) -> Void {
        MRMuvrServer.sharedInstance.apply(MRMuvrServerURLs.SetPublicProfile(userId: userId), body: .Json(params: profile.marshal()), unmarshaller: constUnit(), onComplete: f)
    }
    
    func getProfileImage(f: Result<NSData> -> Void) -> Void {
        MRMuvrServer.sharedInstance.apply(MRMuvrServerURLs.GetProfileImage(userId: userId), onComplete: f)
    }
    
    func setProfileImage(image: NSData) -> Void {
        MRMuvrServer.sharedInstance.apply(MRMuvrServerURLs.SetProfileImage(userId: userId), body: .Data(data: image), unmarshaller: constUnit(), onComplete: constUnit())
    }
    
    // MARK: Session functions
    
    ///
    /// Starts a resistance exercise session with the given properties
    ///
    func startSession(session: MRResistanceExerciseSession) -> MRExercisingApplicationState {
        let id = NSUUID()
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
    func getResistanceExerciseSessionDetails(on date: NSDate) -> [MRResistanceExerciseSessionDetail<MRResistanceExerciseExample>] {
        return MRDataModel.MRResistanceExerciseSessionDataModel.find(on: date)
    }
        
}
