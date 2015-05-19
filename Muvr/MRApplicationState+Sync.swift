import Foundation

extension MRLoggedInApplicationState {
    
    func sync() {
        for ((id, session), sets) in MRDataModel.MRResistanceExerciseSessionDataModel.findUnsynced() {
            let setData = sets.map { $0.marshal() }
            
            let examples = MRDataModel.MRResistanceExerciseSessionDataModel.findResistanceExerciseSetExamplesJson(id)
            let deviations = MRDataModel.MRResistanceExerciseSessionDataModel.findExercisePlanDeviationsJson(id)
            
            let params: [String : AnyObject] = [
                "id":id.UUIDString,
                "session":session.marshal(),
                "sets":JSON(setData).object,
                "examples":JSON(examples).object,
                "deviations":JSON(deviations).object
            ]
            
//            let d = NSJSONSerialization.dataWithJSONObject(params, options: NSJSONWritingOptions.PrettyPrinted, error: nil)!
//            println(NSString(data: d, encoding: NSUTF8StringEncoding))
            
            // pretend it all worked...
            MRMuvrServer.sharedInstance.apply(
                MRMuvrServerURLs.SubmitEntireResistanceExerciseSession(userId: userId, sessionId: id), body: .Json(params: params), unmarshaller: MRSessionId.unmarshal) {
                    $0.cata(constUnit(), r: { MRDataModel.MRResistanceExerciseSessionDataModel.setSynchronised(id, serverId: $0) })
                }
        }
    }
    
}
