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
    
    func postResistanceExample(example: MRResistanceExerciseExample) -> Void {
        let id = NSUUID()
        
        if let c = example.correct {
            MRDataModel.MRResistanceExerciseSessionDataModel.insertResistanceExercise(id, sessionId: sessionId, exercise: c)
        }
        MRDataModel.MRResistanceExerciseSessionDataModel.insertResistanceExerciseExample(id, sessionId: sessionId, example: example)
    }
    
}
