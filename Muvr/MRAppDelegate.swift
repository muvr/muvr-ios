import UIKit
import HealthKit
import MuvrKit
import CoreData

enum MRNotifications : String {
    case CurrentSessionDidEnd = "MRNotificationsCurrentSessionDidEnd"
    case CurrentSessionDidStart = "MRNotificationsCurrentSessionDidStart"
    case SessionDidComplete = "MRNotificationSessionDidComplete"
}

@UIApplicationMain
class MRAppDelegate: UIResponder, UIApplicationDelegate, MKSessionClassifierDelegate {
    
    // TODO: Move to configuration file
    let accessKey = "AKIAIOSFODNN7EXAMPLE"
    let secretKey = "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
    
    var window: UIWindow?
    
    private(set) var sessionStore: MRExerciseSessionStore!
    private(set) var modelStore: MRExerciseModelStore!
    private var connectivity: MKConnectivity!
    private var classifier: MKSessionClassifier!
    private var sessions: [MRManagedExerciseSession] = []
    internal var currentSession: MRManagedExerciseSession? {
        for (session) in sessions where session.end == nil {
            return session
        }
        return nil
    }
    
    ///
    /// Returns the index of a given session
    ///
    private func sessionIndex(session: MKExerciseSession) -> Int? {
        return sessions.indexOf { $0.id == session.id }
    }
    
    ///
    /// Returns this shared delegate
    ///
    static func sharedDelegate() -> MRAppDelegate {
        return UIApplication.sharedApplication().delegate as! MRAppDelegate
    }

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // set up the classification and connectivity
        let remoteStorage = MRS3StorageAccess(accessKey: accessKey, secretKey: secretKey)
        sessionStore = MRExerciseSessionStore(storageAccess: remoteStorage)
        modelStore = MRExerciseModelStore(storageAccess: remoteStorage)
        classifier = MKSessionClassifier(exerciseModelSource: modelStore, delegate: self)
        connectivity = MKConnectivity(sensorDataConnectivityDelegate: classifier, exerciseConnectivitySessionDelegate: classifier)
        
        authorizeHealthKit()
        
        // main initialization
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        window = UIWindow(frame: UIScreen.mainScreen().bounds)
        window!.makeKeyAndVisible()
        window!.rootViewController = storyboard.instantiateInitialViewController()
        
        let pageControlAppearance = UIPageControl.appearance()
        pageControlAppearance.pageIndicatorTintColor = UIColor.lightGrayColor()
        pageControlAppearance.currentPageIndicatorTintColor = UIColor.blackColor()
        pageControlAppearance.backgroundColor = UIColor.whiteColor()
        
        return true
    }
    
    /// manage healthkit access authorisation
    private func authorizeHealthKit() {
        // Only proceed if health data is available.
        guard HKHealthStore.isHealthDataAvailable() else {
            NSLog("HealthKit not available")
            return
        }
        // Ask for permission
        let healthStore = HKHealthStore()
        let typesToShare: Set<HKSampleType> = [HKSampleType.workoutType()]
        let typesToRead: Set<HKSampleType> = [
            HKSampleType.quantityTypeForIdentifier(HKQuantityTypeIdentifierHeartRate)!,
            HKSampleType.quantityTypeForIdentifier(HKQuantityTypeIdentifierActiveEnergyBurned)!
        ]
        healthStore.requestAuthorizationToShareTypes(typesToShare, readTypes: typesToRead) { success, error in
            if success {
                NSLog("HealthKit authorised")
            } else {
                NSLog("Failed to get HealthKit authorisation: \(error)")
            }
        }
    }
    
    func applicationDidBecomeActive(application: UIApplication) {
        application.idleTimerDisabled = true
    }
    
    func applicationWillResignActive(application: UIApplication) {
        application.idleTimerDisabled = false
    }
    
    func sessionClassifierDidEnd(session: MKExerciseSession, sensorData: MKSensorData?) {
        NSLog("Received session end for \(session)")
        // current session may be null in case of no running session
        if let index = sessionIndex(session) {
            let currentSession = sessions[index]
            let objectId = currentSession.objectID
            currentSession.end = session.end
            if let data = sensorData {
                currentSession.sensorData = data.encode()
            }
            NSNotificationCenter.defaultCenter().postNotificationName(MRNotifications.CurrentSessionDidEnd.rawValue, object: objectId)
            saveContext()
        }
    }
    
    func sessionClassifierDidClassify(session: MKExerciseSession, classified: [MKClassifiedExercise], sensorData: MKSensorData) {
        NSLog("Received session classify for \(session)")
        if let index = sessionIndex(session) {
            let currentSession = sessions[index]
            currentSession.sensorData = sensorData.encode()
            currentSession.completed = session.completed
            if session.completed {
                sessions.removeAtIndex(index)
                NSNotificationCenter.defaultCenter().postNotificationName(MRNotifications.SessionDidComplete.rawValue, object: currentSession.objectID)
            }
            classified.forEach { MRManagedClassifiedExercise.insertNewObject(from: $0, into: currentSession, inManagedObjectContext: managedObjectContext) }
        }
        saveContext()
    }
    
    func sessionClassifierDidStart(session: MKExerciseSession) {
         NSLog("Received session start for \(session)")
        let persistedSession = MRManagedExerciseSession.sessionById(session.id, inManagedObjectContext: MRAppDelegate.sharedDelegate().managedObjectContext)
        if persistedSession == nil && sessionIndex(session) == nil {
            let currentSession = MRManagedExerciseSession.insertNewObject(from: session, inManagedObjectContext: managedObjectContext)
            sessions.append(currentSession)
            NSNotificationCenter.defaultCenter().postNotificationName(MRNotifications.CurrentSessionDidStart.rawValue, object: currentSession.objectID)
            saveContext()
        } else if persistedSession != nil && sessionIndex(session) == nil {
            NSLog("cach persisted session into memory: \(persistedSession!)")
            sessions.append(persistedSession!)
        }

    }
    
    func transferModelsMetadata() {
        connectivity.sendModelsMetadata(modelStore.modelsMetadata)
    }
    
    // MARK: - Core Data stack
    
    lazy var applicationDocumentsDirectory: NSURL = {
        // The directory the application uses to store the Core Data store file. This code uses a directory named "io.muvr.CDemo" in the application's documents Application Support directory.
        let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        return urls.first!
    }()
    
    lazy var managedObjectModel: NSManagedObjectModel = {
        // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
        let modelURL = NSBundle.mainBundle().URLForResource("Muvr", withExtension: "momd")!
        return NSManagedObjectModel(contentsOfURL: modelURL)!
    }()
    
    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        // The persistent store coordinator for the application. This implementation creates and returns a coordinator, having added the store for the application to it. This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
        // Create the coordinator and store
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = self.applicationDocumentsDirectory.URLByAppendingPathComponent("MuvrCoreData.sqlite")
        var failureReason = "There was an error creating or loading the application's saved data."
        do {
            try coordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: url, options: nil)
        } catch {
            // Report any error we got.
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data"
            dict[NSLocalizedFailureReasonErrorKey] = failureReason
            
            dict[NSUnderlyingErrorKey] = error as NSError
            let wrappedError = NSError(domain: "io.muvr", code: 9999, userInfo: dict)
            // Replace this with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog("Unresolved error \(wrappedError), \(wrappedError.userInfo)")
            abort()
        }
        
        return coordinator
    }()
    
    lazy var managedObjectContext: NSManagedObjectContext = {
        // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
        let coordinator = self.persistentStoreCoordinator
        var managedObjectContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
    }()
    
    // MARK: - Core Data Saving support
    
    func saveContext () {
        if managedObjectContext.hasChanges {
            do {
                try managedObjectContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                NSLog("Unresolved error \(nserror), \(nserror.userInfo)")
                abort()
            }
        }
    }

}
