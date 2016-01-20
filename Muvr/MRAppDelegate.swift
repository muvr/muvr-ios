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
    case SessionDidEstimate = "MRNotificationSessionDidEstimate"
    case SessionDidClassify = "MRNotificationSessionDidClassify"
    
    case LocationDidObtain = "MRNotificationLocationDidObtain"
    
    case DownloadingModels = "MRNotificationDownloadingModels"
    case ModelsDownloaded = "MRNotificationModelsDownloaded"
    
    case UploadingSessions = "MRNotificationUploadingSessions"
    case SessionsUploaded = "MRNotificationSessionsUploaded"
}

///
/// The MRApp errors
///
enum MRAppError : ErrorType {
    /// A session has not ended yet and a new one tries to start
    case SessionAlreadyInProgress
    /// No active session
    case SessionNotStarted
    /// Unknown session
    case SessionNotFound
}

///
/// The public interface to the app delegate
///
protocol MRApp : MKExercisePropertySource {
    
    ///
    /// The user's current location
    ///
    var locationName: String? { get }

    ///
    /// The list of exercise ids at the current location
    ///
    var exerciseDetails: [MKExerciseDetail] { get }
    
    ///
    /// Performs initial setup
    ///
    func initialSetup()
    
    ///
    /// Explicitly starts an exercise session for the given ``type``.
    /// TODO: ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Does not match the code!
    ///
    /// - parameter exerciseType: the exercise type that the session initially starts with
    /// - returns: the session's identity
    ///
    func startSession(forExerciseType exerciseType: MKExerciseType) throws -> String
    
    ///
    /// Ends the current exercise session, if any
    ///
    func endCurrentSession() throws
}

@UIApplicationMain
class MRAppDelegate: UIResponder, UIApplicationDelegate, CLLocationManagerDelegate,
    MKSessionClassifierDelegate, MKClassificationHintSource, MKExerciseModelSource,
    MRApp {
    
    var window: UIWindow?
    
    private let sessionStoryboard = UIStoryboard(name: "Session", bundle: nil)
    private var sessionViewController: UIViewController?
    private var connectivity: MKAppleWatchConnectivity!
    private var classifier: MKSessionClassifier!
    private var sensorDataSplitter: MKSensorDataSplitter!
    // :( But needed for tests
    private(set) internal var currentSession: MRManagedExerciseSession?
    private var locationManager: CLLocationManager!
    private var currentLocation: MRManagedLocation?

    private var baseExerciseDetails: [MKExerciseDetail] = []
    private var currentLocationExerciseDetails: [MKExerciseDetail] = []
    
    // MARK: - MKClassificationHintSource
    var classificationHints: [MKClassificationHint]? {
        get {
            return currentSession?.classificationHints
        }
    }
    
    // MARK: - MRApp
    var locationName: String? {
        get {
            return currentLocation?.name
        }
    }

    var exerciseDetails: [MKExerciseDetail] = []
    
    ///
    /// Returns this shared delegate
    /// - returns: this delegate ``MRApp``
    ///
    static func sharedDelegate() -> MRApp {
        return UIApplication.sharedApplication().delegate as! MRAppDelegate
    }
    
    // MARK: - UIApplicationDelegate code

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // set up the classification and connectivity
        sensorDataSplitter = MKSensorDataSplitter(exerciseModelSource: self, hintSource: self)
        classifier = MKSessionClassifier(exerciseModelSource: self, sensorDataSplitter: sensorDataSplitter, delegate: self)
        connectivity = MKAppleWatchConnectivity(sensorDataConnectivityDelegate: classifier, exerciseConnectivitySessionDelegate: classifier)

        // Load base configuration
        let baseConfigurationPath = NSBundle.mainBundle().pathForResource("BaseConfiguration", ofType: "bundle")!
        let baseConfiguration = NSBundle(path: baseConfigurationPath)!
        let data = NSData(contentsOfFile: baseConfiguration.pathForResource("exercises", ofType: "json")!)!
        if let allExercises = try! NSJSONSerialization.JSONObjectWithData(data, options: []) as? [[String:AnyObject]] {
            baseExerciseDetails = allExercises.map { exercise in
                guard let id = exercise["id"] as? String,
                      let properties = exercise["properties"] as? [AnyObject]?,
                      let exerciseType = MKExerciseType(exerciseId: id)
                      else { fatalError() }
                
                return (id, exerciseType, properties?.flatMap { MKExerciseProperty(json: $0) } ?? [])
            }
            exerciseDetails = baseExerciseDetails
        } else {
            fatalError()
        }
        
        
        locationManager = CLLocationManager()
        locationManager.delegate = self
        
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
    
        
        // sync
        do {
            try MRLocationSynchronisation().synchronise(inManagedObjectContext: managedObjectContext)
            saveContext()
        } catch let e {
            NSLog(":( \(e)")
        }
        
        // load current session
        if let session = MRManagedExerciseSession.fetchCurrentSession(inManagedObjectContext: managedObjectContext) {
            session.injectPredictors(atLocation: currentLocation, propertySource: self, inManagedObjectContext: managedObjectContext)
            saveContext()
            do { try showSession(session) }
            catch let e {
                NSLog("Failed to display active session \(session.id): \(e)")
            }
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
        if CLLocationManager.authorizationStatus() != CLAuthorizationStatus.AuthorizedWhenInUse {
            locationManager.requestWhenInUseAuthorization()
        }
        application.idleTimerDisabled = true
        locationManager.requestLocation()
    }
    
    func applicationWillResignActive(application: UIApplication) {
        application.idleTimerDisabled = false
    }
    
    private func exerciseIdToLabel(exerciseId: String) -> (MKExercise.Id, MKExerciseTypeDescriptor) {
        if let descriptor = MKExerciseTypeDescriptor(exerciseId: exerciseId) {
            return (exerciseId, descriptor)
        }
        fatalError("Could not extract MKExerciseTypeDescriptor from \(exerciseId).")
    }
    
    // MARK: - Exercise model source
    
    func exerciseModelForExerciseType(exerciseType: MKExerciseType) throws -> MKExerciseModel {
        let path = NSBundle.mainBundle().pathForResource("Models", ofType: "bundle")!
        let modelsBundle = NSBundle(path: path)!
        return try MKExerciseModel(fromBundle: modelsBundle, id: "default", labelExtractor: exerciseIdToLabel)
    }
    
    // MARK: - Session classification
    
    ///
    /// returns the current session if it matches the given id
    /// otherwise fetch it from persistent storage
    ///
    private func findSession(withId id: String) -> MRManagedExerciseSession? {
        if let session = currentSession where session.id == id {
            return session
        }
        return MRManagedExerciseSession.fetchSession(withId: id, inManagedObjectContext: managedObjectContext)
    }
    
    func sessionClassifierDidStart(session: MKExerciseSession) {
        let session = MRManagedExerciseSession.insert(session.id, exerciseType: session.exerciseType, start: session.start, location: currentLocation, inManagedObjectContext: managedObjectContext)
        session.injectPredictors(atLocation: currentLocation, propertySource: self, inManagedObjectContext: managedObjectContext)
        saveContext()
        
        do { try showSession(session) }
        catch let e {
            NSLog("Failed to display new session \(session.id): \(e)")
        }
    }
    
    func sessionClassifierDidEnd(session: MKExerciseSession, sensorData: MKSensorData?) {
        if let currentSession = findSession(withId: session.id) {
            currentSession.end = session.end
            currentSession.completed = session.completed
            currentSession.sensorData = sensorData?.encode()
            endSession(currentSession)
        }
    }
    
    func sessionClassifierDidClassify(session: MKExerciseSession, classified: [MKExerciseWithLabels], sensorData: MKSensorData) {
        if let currentSession = findSession(withId: session.id) {
            currentSession.sensorData = sensorData.encode()
            currentSession.completed = session.completed
            NSNotificationCenter.defaultCenter().postNotificationName(MRNotifications.SessionDidClassify.rawValue, object: currentSession.objectID)
        }
        saveContext()
    }
    
    func sessionClassifierDidEstimate(session: MKExerciseSession, estimated: [MKExerciseWithLabels]) {
        if let currentSession = findSession(withId: session.id) {
            currentSession.estimated = estimated
            NSNotificationCenter.defaultCenter().postNotificationName(MRNotifications.SessionDidEstimate.rawValue, object: currentSession.objectID)
        }
    }
    
    /// MARK: MRAppDelegate actions
    
    func startSession(forExerciseType exerciseType: MKExerciseType) throws -> String {
        let id = NSUUID().UUIDString
        let session = MRManagedExerciseSession.insert(id, exerciseType: exerciseType, start: NSDate(), location: currentLocation, inManagedObjectContext: managedObjectContext)
        session.injectPredictors(atLocation: currentLocation, propertySource: self, inManagedObjectContext: managedObjectContext)
        saveContext()
        
        // notify watch that new session started
        connectivity.startSession(MKExerciseSession(managedSession: session))
        
        try showSession(session)
        
        return id
    }
    
    func endCurrentSession() throws {
        guard let session = currentSession else {
            throw MRAppError.SessionNotStarted
        }
        session.end = NSDate()
        endSession(session)
        
        // notify watch that session ended
        connectivity.endSession(MKExerciseSession(managedSession: session))
    }
    
    ///
    /// Show the active session UI
    /// - parameter: session the session to show
    /// - throws: ``SessionAlreadyInProgress`` if there is already an active session
    ///
    private func showSession(session: MRManagedExerciseSession) throws {
        NSNotificationCenter.defaultCenter().postNotificationName(MRNotifications.CurrentSessionDidStart.rawValue, object: session.objectID)
        if currentSession != nil {
            throw MRAppError.SessionAlreadyInProgress
        }
        currentSession = session
        
        // display ``SessionViewController``
        let svc = sessionStoryboard.instantiateViewControllerWithIdentifier("sessionViewController") as? MRSessionViewController
        svc!.setSession(session)
        window?.rootViewController!.presentViewController(svc!, animated: true, completion: nil)
        sessionViewController = svc
    }
    
    
    ///
    /// Ends the current session if it matches the given session
    /// - parameter session: the session to end
    ///
    private func endSession(session: MRManagedExerciseSession) {
        if let currentSession = currentSession where currentSession == session {
            // dismiss ``SessionViewController``
            sessionViewController?.dismissViewControllerAnimated(true, completion: nil)
            sessionViewController = nil
            self.currentSession = nil
        }
        
        for (id, exerciseType, offset, duration, labels) in session.exerciseWithLabels {
            MRManagedExercise.insertNewObjectIntoSession(session, id: id, exerciseType: exerciseType, labels: labels, offset: offset, duration: duration, inManagedObjectContext: managedObjectContext)
        }
        
        session.savePredictors(atLocation: currentLocation, inManagedObjectContext: managedObjectContext)
        
        NSNotificationCenter.defaultCenter().postNotificationName(MRNotifications.CurrentSessionDidEnd.rawValue, object: session.objectID)
        
        saveContext()
    }
    
    func initialSetup() {
        let polynomialFittingWeight = "pfw"
        let generalWeightProgression: [Double] = [10, 12.5, 15, 17.5, 17.5, 15, 15, 15, 12.5, 12.5, 12.5, 10, 10, 12.5, 10]
        
        let weightPredictor = MKPolynomialFittingScalarPredictor(round: MRScalarRounder.RoundWeight(propertySource: self).rounder)
        for (exerciseId, _, _) in exerciseDetails {
            if let type = MKExerciseType(exerciseId: exerciseId) {
                var multiplier: Double = 1.0
                switch type {
                case .ResistanceTargeted(let muscleGroups) where muscleGroups == [.Legs]: multiplier = 5
                case .ResistanceTargeted(let muscleGroups) where muscleGroups == [.Chest]: multiplier = 3
                case .ResistanceTargeted(let muscleGroups) where muscleGroups == [.Back]: multiplier = 3
                case .ResistanceTargeted(let muscleGroups) where muscleGroups == [.Core]: multiplier = 4
                default: multiplier = 1
                }
                weightPredictor.trainPositional(generalWeightProgression.map { $0 * multiplier }, forExerciseId: exerciseId)
            }
        }
        
        // Next, construct some default plans
        let allExerciseTypes: [MKExerciseType] = [
            .ResistanceTargeted(muscleGroups: [.Arms]),
            .ResistanceTargeted(muscleGroups: [.Core]),
            .ResistanceTargeted(muscleGroups: [.Back]),
            .ResistanceTargeted(muscleGroups: [.Chest]),
            .ResistanceTargeted(muscleGroups: [.Legs]),
            .ResistanceTargeted(muscleGroups: [.Shoulders]),
            .ResistanceWholeBody,
            .IndoorsCardio
        ]
        for exerciseType in allExerciseTypes {
            MRManagedScalarPredictor.upsertScalarPredictor(polynomialFittingWeight, location: nil, sessionExerciseType: exerciseType, data: weightPredictor.json, inManagedObjectContext: managedObjectContext)
        }
        
        saveContext()
    }
    
    // MARK: - Exercise properties
    private let defaultResistanceTargetedProperties: [MKExerciseProperty] = [.WeightProgression(minimum: 0, step: 0.5, maximum: nil)]
    
    func exercisePropertiesForExerciseId(exerciseId: MKExercise.Id) -> [MKExerciseProperty] {
        for (id, exerciseType, properties) in exerciseDetails where id == exerciseId {
            if properties.isEmpty {
                switch exerciseType {
                case .ResistanceTargeted: return defaultResistanceTargetedProperties
                case .IndoorsCardio: return []
                case .ResistanceWholeBody: return []
                }
            }
            return properties
        }
        
        // No exercise id found. This should not happen.
        return []
    }
    
    // MARK: - Core Location stack
    
    private func updatedLocation(location: CLLocation) {
        currentLocation = MRManagedLocation.findAtLocation(location.coordinate, inManagedObjectContext: managedObjectContext)
        if let currentLocation = currentLocation {
            currentLocationExerciseDetails = currentLocation.managedExercises.map { le in
                return (le.id, MKExerciseType(exerciseId: le.id)!, le.properties)
            }
            exerciseDetails =
                currentLocationExerciseDetails +
                baseExerciseDetails.filter { bed in
                    let (beId, _, _) = bed
                    return !currentLocationExerciseDetails.contains { ced in
                        let (ceId, _, _) = ced
                        return ceId == beId
                    }
                }
        } else {
            exerciseDetails = baseExerciseDetails
        }
        
        NSNotificationCenter.defaultCenter().postNotificationName(MRNotifications.LocationDidObtain.rawValue, object: locationName)
    }
    
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        
    }
    
    func locationManager(manager: CLLocationManager, didUpdateToLocation newLocation: CLLocation, fromLocation oldLocation: CLLocation) {
        updatedLocation(newLocation)
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        updatedLocation(locations.last!)
    }
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        #if (arch(i386) || arch(x86_64)) && os(iOS)
            let location = CLLocation(latitude: CLLocationDegrees(53.435739), longitude: CLLocationDegrees(-2.165993))
            updatedLocation(location)
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
