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
            "plan": plan.jsonObject { $0 },
            "items": items.map { $0.jsonObject }
        ]
        return try! NSJSONSerialization.dataWithJSONObject(jsonObject, options: [.PrettyPrinted])
    }
}

///
/// The workout name
//
let workoutName = "Swissball workout"

///
/// the workout exercise type
///
let exerciseType: MKExerciseType = .ResistanceTargeted(muscleGroups: [.Core, .Legs])


///
/// The sequence of exercises to perform in the workout
///
let trx = [

    MKExercisePlanItem(id: "resistanceTargeted:arms/trx-biceps-curl", duration: nil, rest: 30, labels: [.Repetitions(repetitions: 12)]),
    MKExercisePlanItem(id: "resistanceTargeted:arms/trx-biceps-curl", duration: nil, rest: 30, labels: [.Repetitions(repetitions: 12)]),
    
    MKExercisePlanItem(id: "resistanceTargeted:legs/trx-reverse-lunge", duration: nil, rest: 30, labels: [.Repetitions(repetitions: 15)]),
    MKExercisePlanItem(id: "resistanceTargeted:legs/trx-reverse-lunge", duration: nil, rest: 30, labels: [.Repetitions(repetitions: 15)]),
    
    MKExercisePlanItem(id: "resistanceTargeted:legs/trx-hamstring-curl", duration: nil, rest: 30, labels: [.Repetitions(repetitions: 20)]),
    MKExercisePlanItem(id: "resistanceTargeted:legs/trx-hamstring-curl", duration: nil, rest: 30, labels: [.Repetitions(repetitions: 20)]),
    
    MKExercisePlanItem(id: "resistanceTargeted:shoulders/trx-y-deltoid-raises", duration: nil, rest: 30, labels: [.Repetitions(repetitions: 10)]),
    MKExercisePlanItem(id: "resistanceTargeted:shoulders/trx-y-deltoid-raises", duration: nil, rest: 30, labels: [.Repetitions(repetitions: 10)]),
    
    MKExercisePlanItem(id: "resistanceTargeted:chest/trx-chest-press", duration: nil, rest: 30, labels: [.Repetitions(repetitions: 15)]),
    MKExercisePlanItem(id: "resistanceTargeted:chest/trx-chest-press", duration: nil, rest: 30, labels: [.Repetitions(repetitions: 15)]),
    
    MKExercisePlanItem(id: "resistanceTargeted:back/trx-45deg-row", duration: nil, rest: 30, labels: [.Repetitions(repetitions: 20)]),
    MKExercisePlanItem(id: "resistanceTargeted:back/trx-45deg-row", duration: nil, rest: 30, labels: [.Repetitions(repetitions: 20)]),
    
    MKExercisePlanItem(id: "resistanceTargeted:core/trx-atomic-press", duration: nil, rest: 30, labels: [.Repetitions(repetitions: 12)]),
    MKExercisePlanItem(id: "resistanceTargeted:core/trx-atomic-press", duration: nil, rest: 30, labels: [.Repetitions(repetitions: 12)]),
    
    MKExercisePlanItem(id: "resistanceTargeted:core/trx-side-plank", duration: nil, rest: 30, labels: [.Repetitions(repetitions: 20)]),
    MKExercisePlanItem(id: "resistanceTargeted:core/trx-side-plank", duration: nil, rest: 30, labels: [.Repetitions(repetitions: 20)]),
    
    MKExercisePlanItem(id: "resistanceTargeted:arms/trx-triceps-press", duration: nil, rest: 30, labels: [.Repetitions(repetitions: 10)]),
    MKExercisePlanItem(id: "resistanceTargeted:arms/trx-triceps-press", duration: nil, rest: 30, labels: [.Repetitions(repetitions: 10)])
    
]

let sevenMins = [
    MKExercisePlanItem(id: "indoorsCardio:jumping-jacks", duration: 30, rest: 10, labels: nil),
    MKExercisePlanItem(id: "resistanceTargeted:legs/wall-sit", duration: 30, rest: 10, labels: nil),
    MKExercisePlanItem(id: "resistanceTargeted:shoulders/push-up", duration: 30, rest: 10, labels: nil),
    MKExercisePlanItem(id: "resistanceTargeted:core/crunches", duration: 30, rest: 10, labels: nil),
    MKExercisePlanItem(id: "resistanceTargeted:legs/step-up", duration: 30, rest: 10, labels: nil),
    MKExercisePlanItem(id: "resistanceTargeted:legs/squat", duration: 30, rest: 10, labels: nil),
    MKExercisePlanItem(id: "resistanceTargeted:arms/triceps-dips", duration: 30, rest: 10, labels: nil),
    MKExercisePlanItem(id: "resistanceTargeted:core/plank", duration: 30, rest: 10, labels: nil),
    MKExercisePlanItem(id: "indoorsCardio:high-knees-running", duration: 30, rest: 10, labels: nil),
    MKExercisePlanItem(id: "resistanceTargeted:legs/lunges", duration: 30, rest: 10, labels: nil),
    MKExercisePlanItem(id: "resistanceTargeted:shoulders/push-up-with-rotation", duration: 30, rest: 10, labels: nil),
    MKExercisePlanItem(id: "resistanceTargeted:core/side-plank", duration: 30, rest: 10, labels: nil),
    MKExercisePlanItem(id: "resistanceTargeted:core/side-plank", duration: 30, rest: 10, labels: nil)
]

let fatburn = [
    MKExercisePlanItem(id: "indoorsCardio:cross-trainer", duration: 180, rest: 15, labels: nil),
    MKExercisePlanItem(id: "indoorsCardio:cross-trainer", duration: 120, rest: 15, labels: nil),
    MKExercisePlanItem(id: "indoorsCardio:cross-trainer", duration: 120, rest: 15, labels: nil),
    MKExercisePlanItem(id: "indoorsCardio:cross-trainer", duration: 120, rest: 15, labels: nil),
    
    MKExercisePlanItem(id: "resistanceTargeted:legs/leg-press", duration: 60, rest: 15, labels: nil),
    MKExercisePlanItem(id: "resistanceTargeted:shoulders/dumbbell-shoulder-press", duration: 60, rest: 15, labels: nil),
    
    MKExercisePlanItem(id: "indoorsCardio:stepper", duration: 120, rest: 15, labels: nil),
    MKExercisePlanItem(id: "indoorsCardio:stepper", duration: 120, rest: 15, labels: nil),
    MKExercisePlanItem(id: "indoorsCardio:stepper", duration: 120, rest: 15, labels: nil),
    MKExercisePlanItem(id: "indoorsCardio:stepper", duration: 120, rest: 15, labels: nil),
    MKExercisePlanItem(id: "indoorsCardio:stepper", duration: 120, rest: 15, labels: nil),
    MKExercisePlanItem(id: "indoorsCardio:stepper", duration: 300, rest: 15, labels: nil),
    
    MKExercisePlanItem(id: "resistanceTargeted:chest/chest-press", duration: 60, rest: 15, labels: nil),
    
    MKExercisePlanItem(id: "indoorsCardio:running-machine", duration: 300, rest: 15, labels: nil),
    
    MKExercisePlanItem(id: "resistanceTargeted:back/lateral-pulldown", duration: 60, rest: 15, labels: nil),
    
    MKExercisePlanItem(id: "resistanceWholeBody:rope-climbing", duration: 180, rest: 15, labels: nil)
]

let strength = [
    MKExercisePlanItem(id: "resistanceTargeted:chest/bench-press", duration: nil, rest: 60, labels: [.Repetitions(repetitions: 6)]),
    MKExercisePlanItem(id: "resistanceTargeted:chest/bench-press", duration: nil, rest: 60, labels: [.Repetitions(repetitions: 6)]),
    MKExercisePlanItem(id: "resistanceTargeted:chest/bench-press", duration: nil, rest: 60, labels: [.Repetitions(repetitions: 6)]),
    
    MKExercisePlanItem(id: "resistanceTargeted:legs/barbell-squat", duration: nil, rest: 60, labels: [.Repetitions(repetitions: 6)]),
    MKExercisePlanItem(id: "resistanceTargeted:legs/barbell-squat", duration: nil, rest: 60, labels: [.Repetitions(repetitions: 6)]),
    MKExercisePlanItem(id: "resistanceTargeted:legs/barbell-squat", duration: nil, rest: 60, labels: [.Repetitions(repetitions: 6)]),
    
    MKExercisePlanItem(id: "resistanceTargeted:arms/body-weight-dips", duration: nil, rest: 60, labels: [.Repetitions(repetitions: 6)]),
    MKExercisePlanItem(id: "resistanceTargeted:arms/body-weight-dips", duration: nil, rest: 60, labels: [.Repetitions(repetitions: 6)]),
    MKExercisePlanItem(id: "resistanceTargeted:arms/body-weight-dips", duration: nil, rest: 60, labels: [.Repetitions(repetitions: 6)]),
    
    MKExercisePlanItem(id: "resistanceTargeted:legs/barbell-deadlift", duration: nil, rest: 60, labels: [.Repetitions(repetitions: 6)]),
    MKExercisePlanItem(id: "resistanceTargeted:legs/barbell-deadlift", duration: nil, rest: 60, labels: [.Repetitions(repetitions: 6)]),
    MKExercisePlanItem(id: "resistanceTargeted:legs/barbell-deadlift", duration: nil, rest: 60, labels: [.Repetitions(repetitions: 6)]),
    
    MKExercisePlanItem(id: "resistanceTargeted:shoulders/pull-up", duration: nil, rest: 60, labels: [.Repetitions(repetitions: 6)]),
    MKExercisePlanItem(id: "resistanceTargeted:shoulders/pull-up", duration: nil, rest: 60, labels: [.Repetitions(repetitions: 6)]),
    MKExercisePlanItem(id: "resistanceTargeted:shoulders/pull-up", duration: nil, rest: 60, labels: [.Repetitions(repetitions: 6)])
]

let abs = [
    MKExercisePlanItem(id: "resistanceTargeted:core/crunches", duration: 30, rest: 30, labels: nil),
    MKExercisePlanItem(id: "resistanceTargeted:arms/reverse-curl", duration: 30, rest: 30, labels: nil),
    MKExercisePlanItem(id: "resistanceTargeted:core/leg-raises", duration: 30, rest: 30, labels: nil),
    MKExercisePlanItem(id: "resistanceTargeted:core/cable-wood-chop", duration: 30, rest: 30, labels: nil),
    MKExercisePlanItem(id: "resistanceTargeted:core/oblique-crunches", duration: 30, rest: 30, labels: nil),
    MKExercisePlanItem(id: "resistanceTargeted:core/hip-raises", duration: 30, rest: 30, labels: nil),
    MKExercisePlanItem(id: "resistanceTargeted:back/back-extension", duration: 30, rest: 30, labels: nil),
    MKExercisePlanItem(id: "resistanceTargeted:core/plank", duration: 30, rest: 30, labels: nil)
]

let kettlebells = [
    MKExercisePlanItem(id: "resistanceTargeted:legs/sumo-squat", duration: nil, rest: 30, labels: [.Repetitions(repetitions: 15)]),
    MKExercisePlanItem(id: "resistanceWholeBody:kettlebell-tip", duration: nil, rest: 30, labels: [.Repetitions(repetitions: 10)]),
    MKExercisePlanItem(id: "resistanceTargeted:shoulders/single-arm-high-row", duration: nil, rest: 30, labels: [.Repetitions(repetitions: 10)]),
    MKExercisePlanItem(id: "resistanceWholeBody:double-arm-swing", duration: nil, rest: 30, labels: [.Repetitions(repetitions: 15)]),
    MKExercisePlanItem(id: "resistanceWholeBody:double-arm-push-press", duration: nil, rest: 30, labels: [.Repetitions(repetitions: 10)]),
    MKExercisePlanItem(id: "resistanceTargeted:arms/triceps-extension", duration: nil, rest: 30, labels: [.Repetitions(repetitions: 12)]),
    MKExercisePlanItem(id: "resistanceTargeted:back/double-arm-high-pull", duration: nil, rest: 30, labels: [.Repetitions(repetitions: 12)]),
    MKExercisePlanItem(id: "resistanceTargeted:back/windmill", duration: nil, rest: 60, labels: [.Repetitions(repetitions: 6)]),
    MKExercisePlanItem(id: "resistanceTargeted:legs/sumo-squat", duration: nil, rest: 30, labels: [.Repetitions(repetitions: 15)]),
    MKExercisePlanItem(id: "resistanceWholeBody:kettlebell-tip", duration: nil, rest: 30, labels: [.Repetitions(repetitions: 10)]),
    MKExercisePlanItem(id: "resistanceTargeted:shoulders/single-arm-high-row", duration: nil, rest: 30, labels: [.Repetitions(repetitions: 10)]),
    MKExercisePlanItem(id: "resistanceWholeBody:double-arm-swing", duration: nil, rest: 30, labels: [.Repetitions(repetitions: 15)]),
    MKExercisePlanItem(id: "resistanceWholeBody:double-arm-push-press", duration: nil, rest: 30, labels: [.Repetitions(repetitions: 10)]),
    MKExercisePlanItem(id: "resistanceTargeted:arms/triceps-extension", duration: nil, rest: 30, labels: [.Repetitions(repetitions: 12)]),
    MKExercisePlanItem(id: "resistanceTargeted:back/double-arm-high-pull", duration: nil, rest: 30, labels: [.Repetitions(repetitions: 12)]),
    MKExercisePlanItem(id: "resistanceTargeted:back/windmill", duration: nil, rest: 60, labels: [.Repetitions(repetitions: 6)]),
]

let upperbody = [
    MKExercisePlanItem(id: "resistanceTargeted:chest/bench-press", duration: nil, rest: 30, labels: [.Repetitions(repetitions: 15)]),
    MKExercisePlanItem(id: "resistanceTargeted:chest/bench-press", duration: nil, rest: 30, labels: [.Repetitions(repetitions: 15)]),
    
    MKExercisePlanItem(id: "resistanceTargeted:chest/dumbbell-flyes", duration: nil, rest: 30, labels: [.Repetitions(repetitions: 15)]),
    MKExercisePlanItem(id: "resistanceTargeted:chest/dumbbell-flyes", duration: nil, rest: 30, labels: [.Repetitions(repetitions: 15)]),
    
    MKExercisePlanItem(id: "resistanceTargeted:back/lateral-pulldown", duration: nil, rest: 30, labels: [.Repetitions(repetitions: 15)]),
    MKExercisePlanItem(id: "resistanceTargeted:back/lateral-pulldown", duration: nil, rest: 30, labels: [.Repetitions(repetitions: 15)]),
    
    MKExercisePlanItem(id: "resistanceTargeted:arms/barbell-biceps-curl", duration: nil, rest: 30, labels: [.Repetitions(repetitions: 15)]),
    MKExercisePlanItem(id: "resistanceTargeted:arms/barbell-biceps-curl", duration: nil, rest: 30, labels: [.Repetitions(repetitions: 15)]),
    
    MKExercisePlanItem(id: "resistanceTargeted:arms/triceps-pushdown", duration: nil, rest: 30, labels: [.Repetitions(repetitions: 15)]),
    MKExercisePlanItem(id: "resistanceTargeted:arms/triceps-pushdown", duration: nil, rest: 30, labels: [.Repetitions(repetitions: 15)]),
    
    MKExercisePlanItem(id: "resistanceTargeted:shoulders/dumbbell-shoulder-press", duration: nil, rest: 30, labels: [.Repetitions(repetitions: 15)]),
    MKExercisePlanItem(id: "resistanceTargeted:shoulders/dumbbell-shoulder-press", duration: nil, rest: 30, labels: [.Repetitions(repetitions: 15)]),
    
    MKExercisePlanItem(id: "resistanceTargeted:shoulders/lateral-raise", duration: nil, rest: 30, labels: [.Repetitions(repetitions: 15)]),
    MKExercisePlanItem(id: "resistanceTargeted:shoulders/lateral-raise", duration: nil, rest: 30, labels: [.Repetitions(repetitions: 15)]),
    
    MKExercisePlanItem(id: "resistanceTargeted:core/crunches", duration: nil, rest: 30, labels: [.Repetitions(repetitions: 15)]),
    MKExercisePlanItem(id: "resistanceTargeted:core/crunches", duration: nil, rest: 30, labels: [.Repetitions(repetitions: 15)]),
    
    MKExercisePlanItem(id: "resistanceTargeted:arms/reverse-curl", duration: nil, rest: 30, labels: [.Repetitions(repetitions: 15)]),
    MKExercisePlanItem(id: "resistanceTargeted:arms/reverse-curl", duration: nil, rest: 30, labels: [.Repetitions(repetitions: 15)])
]

let cable = [
    MKExercisePlanItem(id: "resistanceTargeted:chest/single-arm-chest-press", duration: nil, rest: 30, labels: [.Repetitions(repetitions: 12)]),
    MKExercisePlanItem(id: "resistanceTargeted:chest/single-arm-chest-press", duration: nil, rest: 30, labels: [.Repetitions(repetitions: 12)]),
    
    MKExercisePlanItem(id: "resistanceTargeted:back/cable-row", duration: nil, rest: 30, labels: [.Repetitions(repetitions: 12)]),
    MKExercisePlanItem(id: "resistanceTargeted:back/cable-row", duration: nil, rest: 30, labels: [.Repetitions(repetitions: 12)]),
    
    MKExercisePlanItem(id: "resistanceTargeted:core/cable-wood-chop", duration: nil, rest: 30, labels: [.Repetitions(repetitions: 12)]),
    MKExercisePlanItem(id: "resistanceTargeted:core/cable-wood-chop", duration: nil, rest: 30, labels: [.Repetitions(repetitions: 12)]),
    
    MKExercisePlanItem(id: "resistanceTargeted:shoulders/single-arm-shoulder-press", duration: nil, rest: 30, labels: [.Repetitions(repetitions: 12)]),
    MKExercisePlanItem(id: "resistanceTargeted:shoulders/single-arm-shoulder-press", duration: nil, rest: 30, labels: [.Repetitions(repetitions: 12)]),
    
    MKExercisePlanItem(id: "resistanceTargeted:arms/triceps-pushdown", duration: nil, rest: 30, labels: [.Repetitions(repetitions: 12)]),
    MKExercisePlanItem(id: "resistanceTargeted:arms/triceps-pushdown", duration: nil, rest: 30, labels: [.Repetitions(repetitions: 12)]),
    
    MKExercisePlanItem(id: "resistanceTargeted:shoulders/single-arm-reverse-fly", duration: nil, rest: 30, labels: [.Repetitions(repetitions: 12)]),
    MKExercisePlanItem(id: "resistanceTargeted:shoulders/single-arm-reverse-fly", duration: nil, rest: 30, labels: [.Repetitions(repetitions: 12)]),
    
    MKExercisePlanItem(id: "resistanceTargeted:shoulders/cable-standing-row", duration: nil, rest: 30, labels: [.Repetitions(repetitions: 12)]),
    MKExercisePlanItem(id: "resistanceTargeted:shoulders/cable-standing-row", duration: nil, rest: 30, labels: [.Repetitions(repetitions: 12)]),
    
    MKExercisePlanItem(id: "resistanceTargeted:legs/cable-kickback", duration: nil, rest: 30, labels: [.Repetitions(repetitions: 12)]),
    MKExercisePlanItem(id: "resistanceTargeted:legs/cable-kickback", duration: nil, rest: 30, labels: [.Repetitions(repetitions: 12)]),
    
    MKExercisePlanItem(id: "resistanceTargeted:chest/cable-crossover", duration: nil, rest: 30, labels: [.Repetitions(repetitions: 12)]),
    MKExercisePlanItem(id: "resistanceTargeted:chest/cable-crossover", duration: nil, rest: 30, labels: [.Repetitions(repetitions: 12)])
]

let swissball = [
    MKExercisePlanItem(id: "indoorsCardio:running-machine", duration: 180, rest: 30, labels: nil),
    MKExercisePlanItem(id: "indoorsCardio:running-machine", duration: 600, rest: 30, labels: nil),
    
    MKExercisePlanItem(id: "resistanceTargeted:legs/wall-sit", duration: 30, rest: 30, labels: nil),
    MKExercisePlanItem(id: "resistanceTargeted:legs/wall-sit", duration: 30, rest: 30, labels: nil),
    
    MKExercisePlanItem(id: "resistanceTargeted:legs/hamstring-curl", duration: nil, rest: 30, labels: [.Repetitions(repetitions: 15)]),
    MKExercisePlanItem(id: "resistanceTargeted:legs/hamstring-curl", duration: nil, rest: 30, labels: [.Repetitions(repetitions: 15)]),
    
    MKExercisePlanItem(id: "resistanceTargeted:shoulders/dumbbell-bench-press", duration: nil, rest: 30, labels: [.Repetitions(repetitions: 15)]),
    MKExercisePlanItem(id: "resistanceTargeted:shoulders/dumbbell-bench-press", duration: nil, rest: 30, labels: [.Repetitions(repetitions: 15)]),
    
    MKExercisePlanItem(id: "resistanceTargeted:arms/triceps-press", duration: nil, rest: 30, labels: [.Repetitions(repetitions: 15)]),
    MKExercisePlanItem(id: "resistanceTargeted:arms/triceps-press", duration: nil, rest: 30, labels: [.Repetitions(repetitions: 15)]),
    
    MKExercisePlanItem(id: "resistanceTargeted:core/plank", duration: 30, rest: 30, labels: nil),
    MKExercisePlanItem(id: "resistanceTargeted:core/plank", duration: 30, rest: 30, labels: nil),
    
    MKExercisePlanItem(id: "resistanceTargeted:back/back-extensions", duration: nil, rest: 30, labels: [.Repetitions(repetitions: 15)]),
    MKExercisePlanItem(id: "resistanceTargeted:back/back-extensions", duration: nil, rest: 30, labels: [.Repetitions(repetitions: 15)]),
    
    MKExercisePlanItem(id: "resistanceTargeted:core/crunches", duration: nil, rest: 30, labels: [.Repetitions(repetitions: 15)]),
    MKExercisePlanItem(id: "resistanceTargeted:core/crunches", duration: nil, rest: 30, labels: [.Repetitions(repetitions: 15)]),
    
    MKExercisePlanItem(id: "indoorsCardio:recumbent-bike", duration: 600, rest: 30, labels: nil),
    MKExercisePlanItem(id: "indoorsCardio:recumbent-bike", duration: 500, rest: 30, labels: nil)
]

let p = MKExercisePlan(id: NSUUID().UUIDString, name: workoutName, exerciseType: exerciseType, items: swissball)

let url = try! NSFileManager.defaultManager().URLForDirectory(.DocumentDirectory, inDomain: .AllDomainsMask, appropriateForURL: NSURL(), create: false).URLByAppendingPathComponent("plan.json")
try! p.prettyJson.writeToURL(url, options: .AtomicWrite)

print("Plan written to \(url.path!)")
print("\n run the following commande and paste into a json file in Muvr/Sessions.bundle/")
print("\n cat \(url.path!) | pbcopy\n")
