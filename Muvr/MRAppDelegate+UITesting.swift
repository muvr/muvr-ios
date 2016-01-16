import UIKit
import MuvrKit

#if !RELEASE

//
// *** DO NOT RUN UI TESTS ON A DEVICE THAT CONTAINS DATA YOU WANT TO KEEP ***
//
// This code completely removes all saved in the app; the next time you start it, it will be empty.
//
// *** DO NOT RUN UI TESTS ON A DEVICE THAT CONTAINS DATA YOU WANT TO KEEP ***
//
extension MRAppDelegate  {
    
    ///
    /// Comments
    ///
    private func exerciseIds() -> [String] {
        return [
            "resistanceTargeted:arms/biceps-curl", "resistanceTargeted:arms/triceps-extension", "resistanceTargeted:shoulders/lateral-raise", "resistanceTargeted:arms/reverse-cable-curl",
            "resistanceTargeted:legs/squat", "resistanceTargeted:legs/lunges", "resistanceTargeted:legs/dumbbell-calf-raise",
            "resistanceTargeted:back/barbell-row", "resistanceTargeted:back/back-extensions", "resistanceTargeted:back/lateral-pulldown-straight",
            "resistanceTargeted:core/oblique-crunches", "resistanceTargeted:core/suitcase-crunches", "resistanceTargeted:core/side-dips", "resistanceTargeted:core/crunches",
            "resistanceTargeted:chest/dumbbell-flyes", "resistanceTargeted:chest/angle-chest-press", "resistanceTargeted:chest/butterfly-machine"
        ]
    }
    
    private func generateSessionData(date date: NSDate) {
        
        func generateClassifiedExercise(date date: NSDate, session: MRManagedExerciseSession, index: Int) {
//            let exercise = MRManagedClassifiedExercise.insertNewObject(inManagedObjectContext: managedObjectContext)
//            exercise.confidence = 1
//            exercise.exerciseId = exerciseIds()[index % exerciseIds().count]
//            exercise.exerciseSession = session
//            exercise.duration = 20 + NSTimeInterval(arc4random() % 30)
//            exercise.cdIntensity = 1
//            exercise.cdRepetitions = 5 + Int(arc4random() % 10)
//            exercise.cdWeight = Double(arc4random() % 50)
//            exercise.start = date.addSeconds(index * 60)
        }

//        let session = MRManagedExerciseSession.insertNewObject(inManagedObjectContext: managedObjectContext)
//        session.id = NSUUID().UUIDString
//        session.exerciseModelId = "arms"
//        session.start = date
//        session.completed = true
//        session.uploaded = true
        
//        (0..<30).forEach { i in generateClassifiedExercise(date: date, session: session, index: i) }
        // (0..<2).forEach { i in generateLabelledExercise(date: date, session: session, index: i) }
    }
    
    private func getSessionDates() -> [NSDate] {
        let today = NSDate()
        let earlierToday = today.addHours(-2)
        var dates = [today, earlierToday]
        (1..<10).forEach { i in
            dates.appendContentsOf([today.addDays(-i), earlierToday.addDays(-i)])
        }
        return dates
    }
    
    private func generateData() {
        getSessionDates().forEach(generateSessionData)
        saveContext()
    }

    func application(application: UIApplication, willFinishLaunchingWithOptions launchOptions: [NSObject : AnyObject]?) -> Bool {
        if Process.arguments.contains("--reset-container") {
            NSLog("Reset container.")
            let fileManager = NSFileManager.defaultManager()
            [NSSearchPathDirectory.DocumentDirectory, NSSearchPathDirectory.ApplicationSupportDirectory].forEach { directory  in
                if let docs = NSSearchPathForDirectoriesInDomains(directory, NSSearchPathDomainMask.UserDomainMask, true).first {
                    (try? fileManager.contentsOfDirectoryAtPath(docs))?.forEach { file in
                        do {
                            try fileManager.removeItemAtPath("\(docs)/\(file)")
                        } catch {
                            // do nothing
                        }
                    }
                }
            }

            if Process.arguments.contains("--default-data") {
                generateData()
            }
        }
        
        return true
    }
    
}
#endif
