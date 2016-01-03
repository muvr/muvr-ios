import UIKit
import HealthKit
import MuvrKit
import CoreData
import CoreLocation

///
/// The notifications: when creating a new notification, be sure to add it only here
/// and never use notification key constants anywhere else.
///
enum MRNotifications : String {
    case CurrentSessionDidEnd = "MRNotificationsCurrentSessionDidEnd"
    case CurrentSessionDidStart = "MRNotificationsCurrentSessionDidStart"
    case SessionDidComplete = "MRNotificationSessionDidComplete"
    case SessionDidEstimate = "MRNotificationSessionDidEstimate"
    case SessionDidClassify = "MRNotificationSessionDidClassify"
    
    case DownloadingModels = "MRNotificationDownloadingModels"
    case ModelsDownloaded = "MRNotificationModelsDownloaded"
    
    case UploadingSessions = "MRNotificationUploadingSessions"
    case SessionsUploaded = "MRNotificationSessionsUploaded"
}

///
/// The public interface to the app delegate
///
protocol MRApp {
    
    ///
    /// The NSManagedObjectContext for the Core Data operations.
    ///
    var managedObjectContext: NSManagedObjectContext { get }
    
    ///
    /// The user's current location
    ///
    var locationName: String? { get }
    
    ///
    /// Saves the pending changes in the app's ``managedObjectContext``.
    ///
    func saveContext()
    
    ///
    /// Returns the exercise ids for the given ``model`` identity
    /// - parameter model: the model identity
    /// - returns: the exercise ids
    ///
    func exerciseIds(model model: MKExerciseModelId) -> [MKExerciseId]
    
}

@UIApplicationMain
class MRAppDelegate: UIResponder, UIApplicationDelegate, CLLocationManagerDelegate,
    MKSessionClassifierDelegate, MKClassificationHintSource, MRApp {
    
    var window: UIWindow?
    
    private var sessionStore: MRExerciseSessionStore!
    private var modelStore: MRExerciseModelStore!
    private var connectivity: MKConnectivity!
    private var classifier: MKSessionClassifier!
    private var sensorDataSplitter: MKSensorDataSplitter!
    private var sessions: [MRManagedExerciseSession] = []
    private var locationManager: CLLocationManager!
    private var currentLocation: MRManagedLocation?
    private var currentSession: MRManagedExerciseSession? {
        for (session) in sessions where session.end == nil {
            return session
        }
        return nil
    }
    
    // MARK: - MKClassificationHintSource
    var exercisingHints: [MKClassificationHint]? {
        get {
            return currentSession?.exercisingHints
        }
    }
    
    // MARK: - MRApp
    var locationName: String? {
        get {
            return currentLocation?.name
        }
    }
    
    // MARK: - Other
    
    ///
    /// Downloads the models
    ///
    private func downloadModels() {
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0)) {
            UIApplication.sharedApplication().networkActivityIndicatorVisible = true
            NSNotificationCenter.defaultCenter().postNotificationName(MRNotifications.DownloadingModels.rawValue, object: nil)
            self.modelStore.downloadModels() {
                NSLog("Stored \(self.modelStore.modelsMetadata)")
                UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                NSNotificationCenter.defaultCenter().postNotificationName(MRNotifications.ModelsDownloaded.rawValue, object: nil)
            }
        }
    }

    ///
    /// Uploads all incomplete sessions
    ///
    private func uploadSessions() {
        func uploadSessions(sessions: [MRManagedExerciseSession]) {
            if let session = sessions.first {
                sessionStore.uploadSession(session) {
                    session.uploaded = true
                    self.saveContext()
                    uploadSessions(Array(sessions.dropFirst()))
                }
            } else {
                UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                NSNotificationCenter.defaultCenter().postNotificationName(MRNotifications.SessionsUploaded.rawValue, object: nil)
            }
        }
        
        let sessions = MRManagedExerciseSession.findUploadableSessions(inManagedObjectContext: managedObjectContext)
        if sessions.isEmpty { return }
        
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0)) {
            UIApplication.sharedApplication().networkActivityIndicatorVisible = true
            NSNotificationCenter.defaultCenter().postNotificationName(MRNotifications.UploadingSessions.rawValue, object: nil)
            uploadSessions(sessions)
        }
    }

    ///
    /// Returns the index of a given session
    /// - parameter session: the session to find the index of
    /// - returns: the index if found
    ///
    private func sessionIndex(session: MKExerciseSession) -> Int? {
        return sessions.indexOf { $0.id == session.id }
    }
    
    ///
    /// Returns the exercise ids for the given ``model``.
    /// - parameter model: the model identity
    /// - returns: the unordered array of exercise ids
    ///
    func exerciseIds(model model: MKExerciseModelId) -> [MKExerciseId] {
        return modelStore.exerciseIds(model: model)
    }
    
    ///
    /// Returns this shared delegate
    /// - returns: this delegate ``MRApp``
    ///
    static func sharedDelegate() -> MRApp {
        return UIApplication.sharedApplication().delegate as! MRAppDelegate
    }
    
    // MARK: - UIApplicationDelegate code

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        let remoteStorage = MRS3StorageAccess(accessKey: AwsCredentials.accessKey, secretKey: AwsCredentials.secretKey)
        sessionStore = MRExerciseSessionStore(storageAccess: remoteStorage)
        modelStore = MRExerciseModelStore(storageAccess: remoteStorage)
        // set up the classification and connectivity
        sensorDataSplitter = MKSensorDataSplitter(exerciseModelSource: modelStore, hintSource: self)
        classifier = MKSessionClassifier(exerciseModelSource: modelStore, sensorDataSplitter: sensorDataSplitter, delegate: self)
        connectivity = MKConnectivity(sensorDataConnectivityDelegate: classifier, exerciseConnectivitySessionDelegate: classifier)
        
        locationManager = CLLocationManager()
        locationManager.delegate = self
        if CLLocationManager.authorizationStatus() != CLAuthorizationStatus.AuthorizedWhenInUse {
            locationManager.requestWhenInUseAuthorization()
        }
        
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
    
        // download the models
        downloadModels()
        
        // sync
        do {
            try MRLocationSynchronisation().synchronise(inManagedObjectContext: managedObjectContext)
            saveContext()
        } catch let e {
            NSLog(":( \(e)")
        }
        
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
        locationManager.requestLocation()
        uploadSessions()
    }
    
    func applicationWillResignActive(application: UIApplication) {
        application.idleTimerDisabled = false
    }
    
    // MARK: - Session classification
    
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
            NSNotificationCenter.defaultCenter().postNotificationName(MRNotifications.SessionDidClassify.rawValue, object: currentSession.objectID)
            if session.completed {
                sessions.removeAtIndex(index)
                NSNotificationCenter.defaultCenter().postNotificationName(MRNotifications.SessionDidComplete.rawValue, object: currentSession.objectID)
            }
            classified.forEach { MRManagedClassifiedExercise.insertNewObject(from: $0, into: currentSession, inManagedObjectContext: managedObjectContext) }
        }
        saveContext()
    }
    
    func sessionClassifierDidEstimate(session: MKExerciseSession, estimated: [MKClassifiedExercise]) {
        if let index = sessionIndex(session) {
            let currentSession = sessions[index]
            currentSession.estimated = estimated
            NSNotificationCenter.defaultCenter().postNotificationName(MRNotifications.SessionDidEstimate.rawValue, object: currentSession.objectID)
        }
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
    
    // MARK: - Core Location stack
    
    func locationManager(manager: CLLocationManager, didUpdateToLocation newLocation: CLLocation, fromLocation oldLocation: CLLocation) {
        NSLog("We're at \(newLocation)")
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        NSLog("We're at \(locations)")
    }
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        #if (arch(i386) || arch(x86_64)) && os(iOS)
            let location = CLLocation(latitude: CLLocationDegrees(53.425416), longitude: CLLocationDegrees(-2.225455))
            currentLocation = MRManagedLocation.findAtLocation(location, inManagedObjectContext: managedObjectContext)
        #endif
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
