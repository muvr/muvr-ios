import Foundation

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
        
        #if false
            MRMuvrServer.sharedInstance.apply(
            MRMuvrServerURLs.ExerciseSessionResistanceExample(userId: userId, sessionId: sessionId),
            body: MRMuvrServer.Body.Json(params: example.marshal()),
            unmarshaller: constUnit(),
            onComplete: constUnit())
        #endif
    }
    
}
