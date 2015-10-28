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
    
    
    private func generateClassifiedExercise(date date: NSDate, session: MRManagedExerciseSession, index: Int) {
        let exercise = MRManagedClassifiedExercise.insertNewObject(inManagedObjectContext: managedObjectContext)
        exercise.confidence = 1
        exercise.exerciseId = ["Biceps curl", "Triceps extension", "Lateral raise"][index % 3]
        exercise.exerciseSession = session
        exercise.duration = 12
        exercise.intensity = 1
        exercise.repetitions = 10
        exercise.weight = 10
        exercise.start = date.addSeconds(index * 60)
    }
    
    private func generateLabelledExercise(date date: NSDate, session: MRManagedExerciseSession, index: Int) {
        let exercise = MRManagedLabelledExercise.insertNewObject(into: session, inManagedObjectContext: managedObjectContext)
        exercise.start = date.addSeconds(index * 60)
        exercise.end = date.addSeconds(index * 60 + 30)
        exercise.exerciseId = ["Biceps curl", "Triceps extension", "Lateral raise"][index % 3]
        exercise.exerciseSession = session
        exercise.intensity = 1
        exercise.weight = 2
        exercise.repetitions = 15
    }
    
    private func generateSessionData(date date: NSDate) {
        let session = MRManagedExerciseSession.insertNewObject(inManagedObjectContext: managedObjectContext)
        session.id = NSUUID().UUIDString
        session.exerciseModelId = "arms"
        session.startDate = date
        
        (0..<10).forEach { i in generateClassifiedExercise(date: date, session: session, index: i) }
        (0..<2).forEach { i in generateLabelledExercise(date: date, session: session, index: i) }
    }
    
    private func generateSessionDates() -> [NSDate] {
        let today = NSDate()
        let earlierToday = today.addHours(-2)
        var dates = [today, earlierToday]
        (1..<10).forEach { i in
            dates.appendContentsOf([today.addDays(-i), earlierToday.addDays(-i)])
        }
        return dates
    }
    
    private func generateData() {
        generateSessionDates().forEach(generateSessionData)
        saveContext()
    }

    func application(application: UIApplication, willFinishLaunchingWithOptions launchOptions: [NSObject : AnyObject]?) -> Bool {
        if Process.arguments.contains("--reset-container") {
            NSLog("Reset container.")
            if let docs = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true).first {
                try! NSFileManager.defaultManager().removeItemAtPath(docs)
                try! NSFileManager.defaultManager().createDirectoryAtPath(docs, withIntermediateDirectories: false, attributes: nil)
            }

            if Process.arguments.contains("--default-data") {
                generateData()
            }
        }
        
        return true
    }
    
}
#endif
