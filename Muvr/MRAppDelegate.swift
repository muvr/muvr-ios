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
    
    case LocationDidObtain = "MRNotificationLocationDidObtain"
    
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
    /// Performs initial setup
    ///
    func initialSetup()
    
    ///
    /// Saves the pending changes in the app's ``managedObjectContext``.
    ///
    func saveContext()
    
    ///
    /// Returns the exercise ids for the given ``model`` identity
    /// - parameter model: the model identity
    /// - returns: the exercise ids
    ///
    func exerciseIds(inModel model: MKExerciseModel.Id) -> [MKExerciseModel.Label]
    
    ///
    /// Explicitly starts an exercise session for the given ``type``.
    /// - parameter type: the exercise type that the session initially starts with
    ///
    func startSessionForExerciseType(type: MKExerciseType)
    
    ///
    /// Ends the current exercise session, if any
    ///
    func endCurrentSession()
}

@UIApplicationMain
class MRAppDelegate: UIResponder, UIApplicationDelegate, CLLocationManagerDelegate,
    MKSessionClassifierDelegate, MKClassificationHintSource, MKScalarRounder,
    MKExerciseModelSource,
    MRApp {
    
    var window: UIWindow?
    
    private let sessionStoryboard = UIStoryboard(name: "Session", bundle: nil)
    private var sessionViewController: UIViewController?
    private var connectivity: MKAppleWatchConnectivity!
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
    private var weightPredictor: MKPolynomialFittingScalarPredictor!
    
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
    /// - returns: the unordered array of exercise ids (excluding exercise ids not available at current location)
    ///
    func exerciseIds(inModel model: MKExerciseModel.Id) -> [MKExerciseModel.Label] {
        let locationExerciseIds = (currentLocation?.exerciseIds ?? []).map(exerciseIdToLabel)
        let modelExerciseIds = (try? getExerciseModel(id: model).labels) ?? []
        
        return locationExerciseIds + modelExerciseIds.filter { (me, _) in
            return !locationExerciseIds.contains { (le, _) in le == me }
        }
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
        // set up the classification and connectivity
        sensorDataSplitter = MKSensorDataSplitter(exerciseModelSource: self, hintSource: self)
        classifier = MKSessionClassifier(exerciseModelSource: self, sensorDataSplitter: sensorDataSplitter, delegate: self)
        connectivity = MKAppleWatchConnectivity(sensorDataConnectivityDelegate: classifier, exerciseConnectivitySessionDelegate: classifier)
        weightPredictor = MKPolynomialFittingScalarPredictor(scalarRounder: self)

        if let p = MRManagedScalarPredictor.scalarPredictorFor("polynomialFitting", location: nil, inManagedObjectContext: managedObjectContext) {
            weightPredictor.mergeJSON(p.data)
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
    
    func getExerciseModel(id id: MKExerciseModel.Id) throws -> MKExerciseModel {
        let path = NSBundle.mainBundle().pathForResource("Models", ofType: "bundle")!
        let modelsBundle = NSBundle(path: path)!
        return try MKExerciseModel(fromBundle: modelsBundle, id: id, labelExtractor: exerciseIdToLabel)
    }
    
    // MARK: - Session UI
    
    private func presentSessionControllerForSession(session: MRManagedExerciseSession) {
        if session.end != nil { return }
        
        //let snvc = sessionStoryboard.instantiateViewControllerWithIdentifier("sessionViewController") as? UINavigationController
        //let svc = snvc?.topViewController as? MRSessionViewController
        let svc = sessionStoryboard.instantiateViewControllerWithIdentifier("sessionViewController") as? MRSessionViewController
        svc!.setSession(session)
        // window!.rootViewController!.navigationController?.presentViewController(sessionViewController!, animated: true, completion: nil)
        window!.rootViewController!.presentViewController(svc!, animated: true, completion: nil)
        sessionViewController = svc
    }
    
    private func dismissSessionControllerForSession(session: MRManagedExerciseSession) {
        if let currentSession = currentSession where currentSession == session {
            sessionViewController?.dismissViewControllerAnimated(true, completion: nil)
            sessionViewController = nil
        }
    }
    
    // MARK: - Session classification
    
    private func endSession(session: MRManagedExerciseSession) {
        dismissSessionControllerForSession(session)
        MRManagedExercisePlan.upsertPlan(session.plan, exerciseType: session.intendedType!, location: currentLocation, inManagedObjectContext: managedObjectContext)
        MRManagedScalarPredictor.upsertScalarPredictor("polynomialFitting", location: currentLocation, data: weightPredictor.json, inManagedObjectContext: managedObjectContext)
        
        NSNotificationCenter.defaultCenter().postNotificationName(MRNotifications.CurrentSessionDidEnd.rawValue, object: session.objectID)
        if session.completed {
            if let index = (sessions.indexOf { $0.objectID == session.objectID }) {
                sessions.removeAtIndex(index)
            }
            NSNotificationCenter.defaultCenter().postNotificationName(MRNotifications.SessionDidComplete.rawValue, object: session.objectID)
        }
        
        saveContext()
    }
    
    func sessionClassifierDidEnd(session: MKExerciseSession, sensorData: MKSensorData?) {
        NSLog("Received session end for \(session)")
        // current session may be null in case of no running session
        if let index = sessionIndex(session) {
            let currentSession = sessions[index]
            endSession(currentSession)
        }
    }
    
    func sessionClassifierDidClassify(session: MKExerciseSession, classified: [MKExerciseWithLabels], sensorData: MKSensorData) {
        NSLog("Received session classify for \(session) with type \(session.exerciseType)")
        if let index = sessionIndex(session) {
            let currentSession = sessions[index]
            currentSession.sensorData = sensorData.encode()
            currentSession.completed = session.completed
            NSNotificationCenter.defaultCenter().postNotificationName(MRNotifications.SessionDidClassify.rawValue, object: currentSession.objectID)
            if session.completed {
                sessions.removeAtIndex(index)
                NSNotificationCenter.defaultCenter().postNotificationName(MRNotifications.SessionDidComplete.rawValue, object: currentSession.objectID)
            }
//            classified.forEach { MRManagedClassifiedExercise.insertNewObject(from: $0, into: currentSession, inManagedObjectContext: managedObjectContext) }
        }
        saveContext()
    }
    
    func sessionClassifierDidEstimate(session: MKExerciseSession, estimated: [MKExerciseWithLabels]) {
        if let index = sessionIndex(session) {
            let currentSession = sessions[index]
            currentSession.estimated = estimated
            NSNotificationCenter.defaultCenter().postNotificationName(MRNotifications.SessionDidEstimate.rawValue, object: currentSession.objectID)
        }
    }
    
    func sessionClassifierDidStart(session: MKExerciseSession) {
        NSLog("Received session start for \(session)")
        let persistedSession = MRManagedExerciseSession.sessionById(session.id, inManagedObjectContext: managedObjectContext)
        if persistedSession == nil && sessionIndex(session) == nil {
            // TODO: load the appropriate plan for type, location and day
            let plan = MRManagedExercisePlan.planForExerciseType(session.exerciseType, location: currentLocation, inManagedObjectContext: managedObjectContext)
            
            let currentSession = MRManagedExerciseSession.insertNewObject(from: session, inManagedObjectContext: managedObjectContext)
            currentSession.locationId = currentLocation?.id
            currentSession.intendedType = session.exerciseType
            currentSession.weightPredictor = weightPredictor

            if let plan = plan?.plan {
                currentSession.plan = plan
            }
            
            sessions.append(currentSession)
            NSNotificationCenter.defaultCenter().postNotificationName(MRNotifications.CurrentSessionDidStart.rawValue, object: currentSession.objectID)
            presentSessionControllerForSession(currentSession)
            saveContext()
        } else if persistedSession != nil && sessionIndex(session) == nil {
            NSLog("cache persisted session into memory: \(persistedSession!)")
            sessions.append(persistedSession!)
        }
    }
    
    func startSessionForExerciseType(type: MKExerciseType) {
        // TODO: resolve model from type
        sessionClassifierDidStart(MKExerciseSession(exerciseType: type))
    }
    
    func endCurrentSession() {
        if let currentSession = currentSession {
            endSession(currentSession)
        }
    }
    
    func initialSetup() {
        let generalWeightProgression: [Double] = [10, 12.5, 15, 17.5, 17.5, 15, 15, 15, 12.5, 12.5, 12.5, 10, 10, 12.5, 10]
        let allExerciseIds = exerciseIds(inModel: "arms").map { $0.0 }
        
        for exerciseId in allExerciseIds {
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
        MRManagedScalarPredictor.upsertScalarPredictor("polynomialFitting", location: nil, data: weightPredictor.json, inManagedObjectContext: managedObjectContext)
        
        // Next, construct some default plans
        /*
        let plan = MKExercisePlan<MKExerciseId>()
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
        */
        
        saveContext()
    }
    
    // MARK: - Exercise properties
    func exercisePropertiesForExerciseId(exerciseId: MKExercise.Id) -> [MKExerciseProperty] {
        // TODO: configurable at location!
        return [.WeightProgression(minimum: 2.5, increment: 2.5, maximum: nil)]
    }
    
    // MARK: - Scalar rounder
    func roundValue(value: Float, forExerciseId exerciseId: MKExercise.Id) -> Float {
        return MKScalarRounderFunction.roundMinMax(value, minimum: 2.5, increment: 2.5, maximum: nil)
    }
    
    // MARK: - Core Location stack
    
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        
    }
    
    func locationManager(manager: CLLocationManager, didUpdateToLocation newLocation: CLLocation, fromLocation oldLocation: CLLocation) {
        currentLocation = MRManagedLocation.findAtLocation(newLocation.coordinate, inManagedObjectContext: managedObjectContext)
        if let p = MRManagedScalarPredictor.scalarPredictorFor("polynomialFitting", location: newLocation.coordinate, inManagedObjectContext: managedObjectContext) {
            weightPredictor.mergeJSON(p.data)
        }
        NSNotificationCenter.defaultCenter().postNotificationName(MRNotifications.LocationDidObtain.rawValue, object: locationName)
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentLocation = MRManagedLocation.findAtLocation(locations.last!.coordinate, inManagedObjectContext: managedObjectContext)
        if let p = MRManagedScalarPredictor.scalarPredictorFor("polynomialFitting", location: locations.last!.coordinate, inManagedObjectContext: managedObjectContext) {
            weightPredictor.mergeJSON(p.data)
        }
        NSNotificationCenter.defaultCenter().postNotificationName(MRNotifications.LocationDidObtain.rawValue, object: locationName)
    }
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        #if (arch(i386) || arch(x86_64)) && os(iOS)
            let location = CLLocation(latitude: CLLocationDegrees(53.435739), longitude: CLLocationDegrees(-2.165993))
            currentLocation = MRManagedLocation.findAtLocation(location.coordinate, inManagedObjectContext: managedObjectContext)
            NSNotificationCenter.defaultCenter().postNotificationName(MRNotifications.LocationDidObtain.rawValue, object: locationName)
            NSLog("\(currentLocation?.exerciseIds)")
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
