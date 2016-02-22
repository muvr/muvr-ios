import Foundation
import CoreData
import MuvrKit

extension MRManagedSessionPlan {
    
    @NSManaged var latitude: NSNumber?
    @NSManaged var longitude: NSNumber?
    @NSManaged private var managedPlan: NSData
    
}

extension MRManagedSessionPlan {
    
    var plan: MKExercisePlan<MKExerciseType> {
        get {
            return MKExercisePlan<MKExerciseType>.fromJsonFirst(managedPlan) {
                guard let json = $0 as? String,
                      let data = json.dataUsingEncoding(NSUTF8StringEncoding),
                      let dict = try? NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments),
                      let metadata = dict as? [String: AnyObject]
                else { return nil }
                return MKExerciseType(metadata: metadata)
            }!
        }
        set {
            managedPlan = newValue.json { exerciseType in
                guard let data = try? NSJSONSerialization.dataWithJSONObject(exerciseType.metadata, options: []),
                      let json = String(data: data, encoding: NSUTF8StringEncoding)
                else { return exerciseType.id } // should not happen
                return json
            }
        }
    }
    
}
