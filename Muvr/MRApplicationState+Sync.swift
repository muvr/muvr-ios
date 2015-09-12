import Foundation
import SwiftyJSON

extension MRLoggedInApplicationState {
    
    func sync() {
        for detail in MRDataModel.MRResistanceExerciseSessionDataModel.findUnsynced() {
            
            let examplesJson = detail.details.map { (e: (MRResistanceExerciseExample, NSData)) -> [String : AnyObject] in
                let (example, fsd) = e
                let jsonData = JSON(data: fsd, options: NSJSONReadingOptions.AllowFragments, error: nil)
                var params: [String : AnyObject] = ["classified" : example.classified.map { $0.marshal() }, "fusedSensorData" : jsonData.object]
                if let c = example.correct {
                    params["correct"] = c.marshal()
                }
                return params
            }
            
            let params: [String : AnyObject] = [
                "id":detail.id.UUIDString,
                "session":detail.session.marshal(),
                "examples":examplesJson
            ]
            
            MRMuvrServer.sharedInstance.apply(
                MRMuvrServerURLs.SubmitEntireResistanceExerciseSession(userId: userId, sessionId: detail.id), body: .Json(params: params), unmarshaller: MRSessionId.unmarshal) {
                    $0.cata( { x in
                        print(x)
                    }, r: { MRDataModel.MRResistanceExerciseSessionDataModel.setSynchronised(detail.id, serverId: $0) })
                }
        }
    }
    
}
