import Foundation

extension MRLoggedInApplicationState {
    
    func sync() {
        for ((id, session), sets) in MRDataModel.MRResistanceExerciseSessionDataModel.findUnsynced() {
            let setData = sets.map { $0.marshal() }
            
            let examples = MRDataModel.MRResistanceExerciseSessionDataModel.findResistanceExerciseExamplesJson(id)
            
            let params: [String : AnyObject] = [
                "id":id.UUIDString,
                "session":session.marshal(),
                "exercises":JSON(setData).object,
                "examples":JSON(examples).object,
            ]
            
            MRMuvrServer.sharedInstance.apply(
                MRMuvrServerURLs.SubmitEntireResistanceExerciseSession(userId: userId, sessionId: id), body: .Json(params: params), unmarshaller: MRSessionId.unmarshal) {
                    $0.cata(constUnit(), r: { MRDataModel.MRResistanceExerciseSessionDataModel.setSynchronised(id, serverId: $0) })
                }
        }
    }
    
}
