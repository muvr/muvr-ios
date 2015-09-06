import Foundation

///
/// Exercising
///
struct MRExercisingApplicationState {
    let sessionId: MRSessionId
    let userId: MRUserId
    let session: MRResistanceExerciseSession
    private var examples: [MRResistanceExerciseExample] = []
    
    init(userId: MRUserId, sessionId: MRSessionId, session: MRResistanceExerciseSession) {
        self.sessionId = sessionId
        self.userId = userId
        self.session = session
    }
    
    mutating func postResistanceExample(example: MRResistanceExerciseExample, fusedSensorData: NSData) -> Void {
        let id = NSUUID()
        examples.append(example)
        MRDataModel.MRResistanceExerciseSessionDataModel.insertResistanceExerciseExample(id, sessionId: sessionId, example: example, fusedSensorData: fusedSensorData)
    }
    
}
