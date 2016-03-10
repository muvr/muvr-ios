//: # Generate exercise plans
//: An easy way to generate an exercise plan:
//: Fill in the `workoutName`, `exerciseType` and `exerciseSequence` for your workout.
//: Then run playground and paste generated JSON into `Muvr/Sessions.bundle/`.
import XCPlayground
@testable import MuvrKit

extension MKExercisePlan {
    
    ///
    /// Generate "pretty" JSON data
    ///
    var prettyJson: NSData {
        let jsonObject = [
            "id": id,
            "name": name,
            "type": exerciseType.metadata,
            "plan": plan.jsonObject { $0 }
        ]
        return try! NSJSONSerialization.dataWithJSONObject(jsonObject, options: [.PrettyPrinted])
    }
}

///
/// The workout name
//
let workoutName = "TRX workout"

///
/// the workout exercise type
///
let exerciseType: MKExerciseType = .ResistanceTargeted(muscleGroups: [.Arms, .Back, .Chest, .Core, .Legs, .Shoulders])


///
/// The sequence of exercises to perform in the workout
///
let exerciseSeq = [

    "resistanceTargeted:arms/trx-biceps-curl",
    "resistanceTargeted:arms/trx-biceps-curl",
    
    "resistanceTargeted:legs/trx-reverse-lunge",
    "resistanceTargeted:legs/trx-reverse-lunge",
    
    "resistanceTargeted:legs/trx-hamstring-curl",
    "resistanceTargeted:legs/trx-hamstring-curl",
    
    "resistanceTargeted:shoulders/trx-y-deltoid-raises",
    "resistanceTargeted:shoulders/trx-y-deltoid-raises",
    
    "resistanceTargeted:chest/trx-chest-press",
    "resistanceTargeted:chest/trx-chest-press",
    
    "resistanceTargeted:back/trx-45deg-row",
    "resistanceTargeted:back/trx-45deg-row",
    
    "resistanceTargeted:core/trx-atomic-press",
    "resistanceTargeted:core/trx-atomic-press",
    
    "resistanceTargeted:core/trx-side-plank",
    "resistanceTargeted:core/trx-side-plank",
    
    "resistanceTargeted:arms/trx-triceps-press",
    "resistanceTargeted:arms/trx-triceps-press"
    
]

let p = MKExercisePlan(id: NSUUID().UUIDString, name: workoutName, exerciseType: exerciseType, plan: MKMarkovPredictor<MKExercise.Id>())

for e in exerciseSeq { p.plan.insert(e) }

let url = try! NSFileManager.defaultManager().URLForDirectory(.DocumentDirectory, inDomain: .AllDomainsMask, appropriateForURL: NSURL(), create: false).URLByAppendingPathComponent("plan.json")
try! p.prettyJson.writeToURL(url, options: .AtomicWrite)

print("Plan written to \(url.path!)")
print("\n run the following commande and paste into a json file in Muvr/Sessions.bundle/")
print("\n cat \(url.path!) | pbcopy\n")
