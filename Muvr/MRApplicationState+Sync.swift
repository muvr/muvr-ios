import Foundation

extension MRLoggedInApplicationState {
    
    func sync() {
        for ((id, session), examples) in MRDataModel.MRResistanceExerciseSessionDataModel.findUnsynced() {
            let params: [String : AnyObject] = [
                "id":id.UUIDString,
                "session":session.marshal(),
                "examples":examples.map { $0.marshal() }
            ]
            
            MRMuvrServer.sharedInstance.apply(
                MRMuvrServerURLs.SubmitEntireResistanceExerciseSession(userId: userId, sessionId: id), body: .Json(params: params), unmarshaller: MRSessionId.unmarshal) {
                    $0.cata(constUnit(), r: { MRDataModel.MRResistanceExerciseSessionDataModel.setSynchronised(id, serverId: $0) })
                }
        }
    }
    
}
