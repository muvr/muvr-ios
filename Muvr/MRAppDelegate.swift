import UIKit
import HealthKit
import MuvrKit
import CoreMotion
import CoreData
import CoreLocation

/// The connected watch
enum ConnectedWatch {
    case appleWatch
    case pebble
}

///
/// The notifications: when creating a new notification, be sure to add it only here
/// and never use notification key constants anywhere else.
///
enum MRNotifications : String {
    case SessionDidEnd = "MRNotificationsCurrentSessionDidEnd"
    case SessionDidStart = "MRNotificationsCurrentSessionDidStart"
    case SessionDidStartExercise = "MRNotificationSessionDidStartExercise"
    case SessionDidEndExercise = "MRNotificationSessionDidEndExercise"
    
    case LocationDidObtain = "MRNotificationLocationDidObtain"
    
    case DownloadingModels = "MRNotificationDownloadingModels"
    case ModelsDownloaded = "MRNotificationModelsDownloaded"
    
    case UploadingSessions = "MRNotificationUploadingSessions"
    case SessionsUploaded = "MRNotificationSessionsUploaded"
}

///
/// The MRApp errors
///
enum MRAppError : ErrorProtocol {
    /// A session has not ended yet and a new one tries to start
    case sessionAlreadyInProgress
    /// No active session
    case sessionNotStarted
}

///
/// The public interface to the app delegate
///
protocol MRApp : MKExercisePropertySource {

    ///
    /// Indicates that the device is steady and level for some duration of time; this typically
    /// means that the user has placed the phone on the floor.
    ///
    /// This is useful to detect when the user is "messing" with his or her device, and therefore
    /// unlikely to benefit from automatic exercising -> not exercising transitions.
    ///
    var deviceSteadyAndLevel: Bool { get }
    
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
    /// Start a session with the given ``sessionType``
    /// - parameter sessionType: the type that the session initially starts with
    /// - returns: the session's identity
    ///
    func startSession(_ sessionType: MRSessionType) throws -> String
    
    ///
    ///
    ///
    func exerciseStarted(_ exercise: MKExerciseDetail, start: Date)
    
    ///
    /// Ends the current exercise session, if any
    ///
    func endCurrentSession() throws
    
    ///
    /// Ordered list (most likely first) of the available workouts
    ///
    var sessionTypes: [MRSessionType] { get }
    
    ///
    /// Predefined list (alphabetical order) of the predefined workouts
    ///
    var predefinedSessionTypes: [MRSessionType] { get }

    ///
    /// Returns true if there are sessions on the given date
    ///
    func hasSessionsOnDate(_ date: Date) -> Bool
    
    ///
    /// Returns the sessions found on the given date
    ///
    func sessionsOnDate(_ date: Date) -> [MRManagedExerciseSession]
    
    ///
    /// Returns the achievements for the given session type
    ///
    func achievementsForSessionType(_ sessionType: MRSessionType) -> [MRAchievement]

}

///
/// This is a marker interface for things we should not be doing, but don't
/// know how to do better now. All its methods should be marked as ``throws``,
/// so that their usage must use ``try`` (even better, ``try!``), even though
/// they do not throw exceptions.
///
protocol MRSuperEvilMegacorpApp {
    
    func mainManagedObjectContext() throws -> NSManagedObjectContext
    
}

//@UIApplicationMain
class MRAppDelegate: UIResponder, UIApplicationDelegate, CLLocationManagerDelegate,
    MKSessionClassifierDelegate, MKClassificationHintSource, MKExerciseModelSource,
    MRApp, MRSuperEvilMegacorpApp {
    
    let connectedWatch = ConnectedWatch.pebble
    
    var window: UIWindow?
    
    private let sessionStoryboard = UIStoryboard(name: "Session", bundle: nil)
    private var sessionViewController: MRSessionViewController?
    private var connectivity: MKDeviceConnectivity!
    private var classifier: MKSessionClassifier!
    private var sensorDataSplitter: MKSensorDataSplitter!
    private var sessionPlan: MRManagedSessionPlan!
    private var motionManager: CMMotionManager!
    // :( But needed for tests
    private(set) internal var currentSession: MRManagedExerciseSession?
    private var locationManager: CLLocationManager!
    private var currentLocation: MRManagedLocation?

    private var baseExerciseDetails: [MKExerciseDetail] = []
    private var currentLocationExerciseDetails: [MKExerciseDetail] = []

    // MARK: - Device steady and level

    private var deviceMotionEndTimestap: CFTimeInterval? = nil
    
    private var setupExerciseModel: MKExerciseModel? = nil

    private func deviceMotionUpdate(_ motion: CMDeviceMotion?, error: NSError?) {
        if let motion = motion {
            if abs(motion.gravity.x) > 0.1 ||
               abs(motion.gravity.y) > 0.1 ||
               abs(motion.gravity.z) < 0.9 {
               deviceMotionEndTimestap = CFAbsoluteTimeGetCurrent()
            }
        }
    }

    var deviceSteadyAndLevel: Bool {
        get {
            return deviceMotionEndTimestap.map { CFAbsoluteTimeGetCurrent() - $0 > 5 } ?? false
        }
    }

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
    
    func hasSessionsOnDate(_ date: Date) -> Bool {
        return MRManagedExerciseSession.hasSessionsOnDate(date, inManagedObjectContext: managedObjectContext)
    }
    
    func sessionsOnDate(_ date: Date) -> [MRManagedExerciseSession] {
        return MRManagedExerciseSession.fetchSessionsOnDate(date, inManagedObjectContext: managedObjectContext)
    }
    
    ///
    /// Returns this shared delegate
    /// - returns: this delegate ``MRApp``
    ///
    static func sharedDelegate() -> MRApp {
        return UIApplication.shared().delegate as! MRAppDelegate
    }
    
    ///
    /// Returns the dangerous self
    /// - returns: this delegate as ``MRSuperEvilMegacorpApp``
    ///
    static func superEvilMegacorpSharedDelegate() -> MRSuperEvilMegacorpApp {
        return UIApplication.shared().delegate as! MRSuperEvilMegacorpApp
    }
    
    // MARK: - MRSuperEvilMegacorpApp
    
    func mainManagedObjectContext() throws -> NSManagedObjectContext {
        return managedObjectContext
    }
    
    // MARK: - UIApplicationDelegate code

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // set up the classification
        sensorDataSplitter = MKSensorDataSplitter(exerciseModelSource: self, hintSource: self)
        classifier = MKSessionClassifier(exerciseModelSource: self, sensorDataSplitter: sensorDataSplitter, delegate: self)
        
        // set up watch connectivity
        switch connectedWatch {
        case .pebble: connectivity = MKPebbleConnectivity(sensorDataConnectivityDelegate: classifier, exerciseConnectivitySessionDelegate: classifier)
        case .appleWatch: connectivity = MKAppleWatchConnectivity(sensorDataConnectivityDelegate: classifier, exerciseConnectivitySessionDelegate: classifier)
        }

        // Load base configuration
        let baseConfigurationPath = Bundle.main().pathForResource("BaseConfiguration", ofType: "bundle")!
        let baseConfiguration = Bundle(path: baseConfigurationPath)!
        let data = try! Data(contentsOf: URL(fileURLWithPath: baseConfiguration.pathForResource("exercises", ofType: "json")!))
        if let allExercises = try! JSONSerialization.jsonObject(with: data, options: []) as? [[String:AnyObject]] {
            baseExerciseDetails = allExercises.map { exercise in
                guard let id = exercise["id"] as? String,
                      let propertiesObject = exercise["properties"] as? [AnyObject]?,
                      let exerciseType = MKExerciseType(exerciseId: id),
                      let labelNames = exercise["labels"] as? [String]
                      else { fatalError() }
                var properties = propertiesObject?.flatMap { MKExerciseProperty(jsonObject: $0) } ?? []
                if properties.isEmpty {
                    switch exerciseType {
                    case .resistanceTargeted: properties = defaultResistanceTargetedProperties
                    case .indoorsCardio, .resistanceWholeBody: properties = []
                    }
                }
                let labels = labelNames.flatMap { MKExerciseLabelDescriptor(id: $0) }
                let muscle = (exercise["muscle"] as? String).flatMap { MKMuscle(id: $0) }
                return MKExerciseDetail(id: id, type: exerciseType, muscle: muscle, labels: labels, properties: properties)
            }
            exerciseDetails = baseExerciseDetails
        } else {
            fatalError()
        }
        
        
        locationManager = CLLocationManager()
        locationManager.delegate = self

        motionManager = CMMotionManager()
        motionManager.deviceMotionUpdateInterval = 0.25

        authorizeHealthKit()
        
        loadSessionPlan()
        
        
        // appearrance
        UITabBar.appearance().tintColor = UIColor.white()
        UITabBarItem.appearance().setTitleTextAttributes([NSForegroundColorAttributeName: UIColor.white()], for: UIControlState())
        UINavigationBar.appearance().tintColor = UIColor.white()
        UINavigationBar.appearance().backgroundColor = MRColor.darkBlue
        UIView.appearance().tintColor = MRColor.darkBlue
        UIView.whenContained(inInstancesOfClasses: [UINavigationBar.self]).tintColor = .white()
        UIView.whenContained(inInstancesOfClasses: [MRCircleView.self]).tintColor = MRColor.black
        
        let pageControlAppearance = UIPageControl.appearance()
        pageControlAppearance.pageIndicatorTintColor = UIColor.lightGray()
        pageControlAppearance.currentPageIndicatorTintColor = UIColor.black()
        pageControlAppearance.backgroundColor = UIColor.white()
        
        // main initialization
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        window = UIWindow(frame: UIScreen.main().bounds)
        window!.makeKeyAndVisible()
        window!.rootViewController = storyboard.instantiateInitialViewController()
        
        // sync
        do {
            try MRLocationSynchronisation().synchronise(inManagedObjectContext: managedObjectContext)
            saveContext()
        } catch {
            NSLog(":( \(error)")
        }
        
        return true
    }

    /// MARK: HealthKit
    
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
            HKSampleType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate)!,
            HKSampleType.quantityType(forIdentifier: HKQuantityTypeIdentifier.activeEnergyBurned)!
        ]
        healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { success, error in
            if success {
                NSLog("HealthKit authorised")
            } else {
                NSLog("Failed to get HealthKit authorisation: \(error)")
            }
        }
    }
    
    /// save workout into healthkit
    private func addSessionToHealthKit(_ session: MRManagedExerciseSession) {
        // Only proceed if health data is available.
        if !HKHealthStore.isHealthDataAvailable() {
            NSLog("HealthKit not available")
            return
        }
        // Only proceed if no apple watch available (otherwise workout is saved by the watch)
        if connectedWatch == .appleWatch && connectivity.reachable {
            NSLog("HealthKit workout saved by Apple watch")
            return
        }
        
        let healthStore = HKHealthStore()
        if healthStore.authorizationStatus(for: HKObjectType.workoutType()) != .sharingAuthorized {
            NSLog("Healthkit saving workout not authorised")
            return
        }
        
        let start = session.start
        let end = session.end ?? Date()
        let duration = end.timeIntervalSince(start as Date)
        
        let workout = HKWorkout(activityType: HKWorkoutActivityType.traditionalStrengthTraining, start: start as Date, end: end as Date, duration: duration, totalEnergyBurned: nil, totalDistance: nil, metadata: ["session":session.name])
        healthStore.save(workout) { success, error in
            if let error = error where !success {
                NSLog("Failed to save workout: \(error)")
                return
            }
            NSLog("Workout saved to healthkit")
        }
    }
    
    func loadSessionPlan() {
        sessionPlan = MRManagedSessionPlan.find(inManagedObjectContext: managedObjectContext) ??
            MRManagedSessionPlan.insertNewObject(MKMarkovPredictor<MKExercisePlan.Id>(), inManagedObjectContext: managedObjectContext)
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        if CLLocationManager.authorizationStatus() != CLAuthorizationStatus.authorizedWhenInUse {
            locationManager.requestWhenInUseAuthorization()
        }
        motionManager.startDeviceMotionUpdates(to: OperationQueue.main(), withHandler: deviceMotionUpdate)
        application.isIdleTimerDisabled = currentSession != nil
        locationManager.requestLocation()
    }

    func applicationWillResignActive(_ application: UIApplication) {
        application.isIdleTimerDisabled = false
    }
    
    private func exerciseIdToLabel(_ exerciseId: String) -> (MKExercise.Id, MKExerciseTypeDescriptor) {
        if let descriptor = MKExerciseTypeDescriptor(exerciseId: exerciseId) {
            return (exerciseId, descriptor)
        }
        fatalError("Could not extract MKExerciseTypeDescriptor from \(exerciseId).")
    }
    
    // MARK: - Exercise model source
    
    func exerciseModelForExerciseType(_ exerciseType: MKExerciseType) throws -> MKExerciseModel {
        let path = Bundle.main().pathForResource("Models", ofType: "bundle")!
        let modelsBundle = Bundle(path: path)!
        return try MKExerciseModel(fromBundle: modelsBundle, id: "default", labelExtractor: exerciseIdToLabel)
    }
    
    func exerciseModelForExerciseSetup() throws -> MKExerciseModel {
        if setupExerciseModel == nil {
            let path = Bundle.main().pathForResource("Models", ofType: "bundle")!
            let modelsBundle = Bundle(path: path)!
            try setupExerciseModel = MKExerciseModel(fromBundle: modelsBundle, id: "setup", labelExtractor: exerciseIdToLabel)
        }
        
        return setupExerciseModel!
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
    
    func sessionClassifierDidStartSession(_ session: MKExerciseSession) {
        if let currentSession = currentSession {
            // Watch is running wrong session, update it with current session
            connectivity.startSession(MKExerciseSession(managedSession: currentSession))
            // ignore watch's session
            return
        }
        
        // get the exercise plan for this session
        let sessionType: MRSessionType = .adHoc(exerciseType: session.exerciseType)  // no predefined plan on the watch, yet
        let plan = MRManagedExercisePlan.planForSessionType(sessionType, location: currentLocation, inManagedObjectContext: managedObjectContext)
        
        // no running session, let's start a new one
        let session = MRManagedExerciseSession.insert(session.id, plan: plan, start: session.start, location: currentLocation, inManagedObjectContext: managedObjectContext)
        injectPredictors(into: session)
        saveContext()
        
        showSession(session)
    }

    func sessionClassifierDidEndSession(_ session: MKExerciseSession, sensorData: MKSensorData?) {
        if let currentSession = findSession(withId: session.id) {
            currentSession.end = session.end
            currentSession.completed = session.completed
            currentSession.sensorData = sensorData?.encode()
            saveAndExport(sensorData, session: currentSession)
            terminateSession(currentSession)
        }
    }

    func saveAndExport(_ sensorData: MKSensorData?, session: MRManagedExerciseSession) {
        if sensorData == nil {
            NSLog("Sensor data is nil, pebble connectivity lost!")
            alert("Pebble connectivity lost".localized(), message: "This session couldn't be saved! You need to restart the pebble app".localized())
            return
        }
        let csvData: Data = sensorData!.encodeAsCsv(session.exerciseWithLabels)
        let now = Date(timeIntervalSinceNow: Double(TimeZone.local().secondsFromGMT))
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "YYYY-MM-dd'T'HH-mm-ss'Z'"
        dateFormatter.timeZone = TimeZone(forSecondsFromGMT: 0)
        let filename = dateFormatter.string(from: now)
        let exportFilePath = NSTemporaryDirectory() + "\(filename).csv"
        let exportFileURL = URL(fileURLWithPath: exportFilePath)
        FileManager.default().createFile(atPath: exportFilePath, contents: Data(), attributes: nil)

        do {
            let fileHandle = try FileHandle(forWritingTo: exportFileURL)
            fileHandle.seekToEndOfFile()
            fileHandle.write(csvData)
            fileHandle.closeFile()
            NSLog("Session Saved to \(filename)")
            shareSession(exportFilePath)
        } catch {
            NSLog("Error with fileHandle, filename: \(filename), error: \(error)")
        }
    }

    func alert(_ title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Done".localized(), style: UIAlertActionStyle.default, handler: nil))
        self.window?.rootViewController!.present(alert, animated: true, completion: nil)
    }

    func shareSession(_ exportFilePath: String) {
        let firstActivityItem = URL(fileURLWithPath: exportFilePath)
        let activityViewController : UIActivityViewController = UIActivityViewController(
            activityItems: [firstActivityItem], applicationActivities: nil)

        activityViewController.excludedActivityTypes = [
            UIActivityTypeAssignToContact,
            UIActivityTypeSaveToCameraRoll,
            UIActivityTypePostToFlickr,
            UIActivityTypePostToVimeo,
            UIActivityTypePostToTencentWeibo
        ]
        NSLog("Sharing Session: \(exportFilePath)")
        self.window?.rootViewController!.present(activityViewController, animated: true, completion: nil)
    }
    
    func sessionClassifierDidSetupExercise(_ session: MKExerciseSession, trigger: MKSessionClassifierDelegateStartTrigger) -> MKExerciseSession.State? {
        if let currentSession = findSession(withId: session.id) {
            switch trigger {
            case .setupDetected(let exercises):
                if let (exerciseId, probability) = exercises.last { //TODO: send the last one or all
                    sessionViewController!.exerciseSetupDetected(exerciseId, probability: probability)
                }
            default:
                break
            }

            return currentSession.sessionClassifierDidSetupExercise(trigger)
        }
        return nil
    }
    
    func repsCountFeed(_ session: MKExerciseSession, reps: Int, start: Date, end: Date) {
        if (findSession(withId: session.id) != nil) {
            sessionViewController!.repsCountFeed(reps, start: start, end: end)
        }
    }

    func sessionClassifierDidStartExercise(_ session: MKExerciseSession, trigger: MKSessionClassifierDelegateStartTrigger) -> MKExerciseSession.State? {
        if let currentSession = findSession(withId: session.id) {
            return currentSession.sessionClassifierDidStartExercise(trigger)
        }
        return nil
    }
    
    func sessionClassifierDidEndExercise(_ session: MKExerciseSession, trigger: MKSessionClassifierDelegateEndTrigger) -> MKExerciseSession.State? {
        if let currentSession = findSession(withId: session.id) {
            return currentSession.sessionClassifierDidEndExercise(trigger)
        }
        return nil
    }
    
    /// MARK: MRAppDelegate actions
    
    func startSession(_ sessionType: MRSessionType) throws -> String {
        if currentSession != nil {
            throw MRAppError.sessionAlreadyInProgress
        }
        
        let id = UUID().uuidString
        let plan = MRManagedExercisePlan.planForSessionType(sessionType, location: currentLocation, inManagedObjectContext: managedObjectContext)
        let session = MRManagedExerciseSession.insert(id, plan: plan, start: Date(), location: currentLocation, inManagedObjectContext: managedObjectContext)
        
        injectPredictors(into: session)
        saveContext()
        
        showSession(session)
        
        // notify watch that new session started
        connectivity.startSession(MKExerciseSession(managedSession: session))
        
        return id
    }
    
    func exerciseStarted(_ exercise: MKExerciseDetail, start: Date) {
        connectivity.exerciseStarted(exercise, start: start)
    }
    
    func endCurrentSession() throws {
        guard let session = currentSession else {
            throw MRAppError.sessionNotStarted
        }
        session.end = Date()
        terminateSession(session)
        
        // notify watch that session ended
        connectivity.endSession(MKExerciseSession(managedSession: session))
    }
    
    ///
    /// Show the active session UI
    /// - parameter: session the session to show
    ///
    private func showSession(_ session: MRManagedExerciseSession) {
        currentSession = session
        
        // display ``SessionViewController``
        if let nvc = sessionStoryboard.instantiateViewController(withIdentifier: "sessionNavigationViewController") as? UINavigationController,
            let svc = nvc.viewControllers.first as? MRSessionViewController {
            svc.setSession(session)
            sessionViewController = svc
            window?.rootViewController?.present(nvc, animated: true, completion: nil)
        }
        
        // keep application active while in-session
        UIApplication.shared().isIdleTimerDisabled = true
        
        NotificationCenter.default().post(name: Notification.Name(rawValue: MRNotifications.SessionDidStart.rawValue), object: session.objectID)
    }
    
    
    ///
    /// Ends the current session if it matches the given session
    /// - parameter session: the session to end
    ///
    private func terminateSession(_ session: MRManagedExerciseSession) {
        if let currentSession = currentSession where currentSession == session {
            // dismiss ``SessionViewController``
            sessionViewController?.dismiss(animated: true, completion: nil)
            self.currentSession = nil
            UIApplication.shared().isIdleTimerDisabled = false
        }
        
        // save exercises
        for (id, exerciseType, offset, duration, labels) in session.exerciseWithLabels {
            MRManagedExercise.insertNewObjectIntoSession(session, id: id, exerciseType: exerciseType, labels: labels, offset: offset, duration: duration, inManagedObjectContext: managedObjectContext)
        }
        
        // save predictors
        session.plan.save()
        MRManagedLabelsPredictor.upsertPredictor(location: currentLocation, sessionExerciseType: session.exerciseType, data: session.labelsPredictor.json, inManagedObjectContext: managedObjectContext)
        
        NotificationCenter.default().post(name: Notification.Name(rawValue: MRNotifications.SessionDidEnd.rawValue), object: session.objectID)
        
        // add workout to healthkit
        addSessionToHealthKit(session)
        
        // check if user deserves any achievements
        recordAchievementsForSession(session)
        
        saveContext()
    }
    
    ///
    /// inject the predictors in the given session
    ///
    func injectPredictors(into session: MRManagedExerciseSession) {
      let predictor = MRManagedLabelsPredictor.predictorFor(location: currentLocation, sessionExerciseType: session.exerciseType, inManagedObjectContext: managedObjectContext)
        session.labelsPredictor = predictor.map { MKAverageLabelsPredictor(json: $0.data, historySize: 3, round: roundLabel) } ?? MKAverageLabelsPredictor(historySize: 3, round: roundLabel)
        
        if let templateId = session.plan.templateId,
            let predefPlan = exercisePlans.filter({ $0.id == templateId }).first {
            session.labelsPredictor.loadPredefinedPlan(predefPlan)
        }
        
        sessionPlan.insert(session.plan.id)
    }
    
    ///
    /// Check and save user achievements for the given session
    ///
    private func recordAchievementsForSession(_ session: MRManagedExerciseSession) {
        guard let templateId = session.plan.templateId,
            let template = exercisePlans.filter({ $0.id == templateId }).first else { return }
        
        let fromDate = Date().addDays(-30)
        let sessions = session.fetchSimilarSessionsSinceDate(fromDate, inManagedObjectContext: managedObjectContext)
        guard let achievement = MRSessionAppraiser().achievementForSessions(sessions, plan: template) else { return }
        
        _ = MRManagedAchievement.insertNewObject(achievement, plan: session.plan, inManagedObjectContext: managedObjectContext)
    }
    
    func initialSetup() { }
    
    // MARK: - Scalar rounder
    
    private func roundLabel(_ label: MKExerciseLabelDescriptor, value: Double, forExerciseId exerciseId: MKExercise.Id) -> Double {
        switch label {
        case .weight: return roundWeight(value, forExerciseId: exerciseId)
        case .repetitions: return roundInteger(value, forExerciseId: exerciseId)
        case .intensity: return roundClipToNorm(value, forExerciseId: exerciseId)
        }
    }
    
    private func roundInteger(_ value: Double, forExerciseId exerciseId: MKExercise.Id) -> Double {
        return Double(Int(max(0, value)))
    }
    
    private func noRound(_ value: Double, forExerciseId exerciseId: MKExercise.Id) -> Double {
        return max(0, value)
    }
    
    private func roundClipToNorm(_ value: Double, forExerciseId exerciseId: MKExercise.Id) -> Double {
        let x = Int(round(min(5, max(0, value * 5))))
        return Double(x) / 5
    }
    
    private func roundWeight(_ value: Double, forExerciseId exerciseId: MKExercise.Id) -> Double {
        guard let detail = exerciseDetailForExerciseId(exerciseId) else { return max(0, value) }
        for property in detail.properties {
            if case .weightProgression(let minimum, let step, let maximum) = property {
                return MKScalarRounderFunction.roundMinMax(value, minimum: minimum, step: step, maximum: maximum)
            }
        }
        return max(0, value)
    }
    
    private func steps(forLabel label: MKExerciseLabelDescriptor, value: Double, steps: Int, forExerciseId exerciseId: MKExercise.Id) -> Double {
        switch label {
        case .weight: return stepWeight(value, n: steps, forExerciseId: exerciseId)
        case .repetitions: return stepInteger(value, n: steps, forExerciseId: exerciseId)
        case .intensity: return stepIntensity(value, n: steps, forExerciseId: exerciseId)
        }
    }
    
    private func stepWeight(_ value: Double, n: Int, forExerciseId exerciseId: MKExercise.Id) -> Double {
        guard let detail = exerciseDetailForExerciseId(exerciseId) else { return value + Double(n) }
        for property in detail.properties {
            if case .weightProgression(let minimum, let step, let maximum) = property {
                return min(maximum ?? 999, max(minimum, value + Double(n) * step))
            }
        }
        return value + Double(n)
    }
    
    private func stepIntensity(_ value: Double, n: Int, forExerciseId exerciseId: MKExercise.Id) -> Double {
        return value + Double(n) * 0.2
    }
    
    private func stepInteger(_ value: Double, n: Int, forExerciseId exerciseId: MKExercise.Id) -> Double {
        return value + Double(n)
    }
    
    // MARK: - Exercise properties
    private let defaultResistanceTargetedProperties: [MKExerciseProperty] = [.weightProgression(minimum: 0, step: 0.5, maximum: nil)]
    
    func exerciseDetailForExerciseId(_ exerciseId: MKExercise.Id) -> MKExerciseDetail? {
        for exerciseDetail in exerciseDetails where exerciseDetail.id == exerciseId {
            return exerciseDetail
        }
        
        // No exercise id found. This should not happen.
        return nil
    }
    
    // MARK: - Exercise plans
    
    ///
    /// the configured exercise plans
    ///
    private var exercisePlans: [MKExercisePlan] {
        let bundlePath = Bundle(for: MRAppDelegate.self).pathForResource("Sessions", ofType: "bundle")!
        let bundle = Bundle(path: bundlePath)!
        return bundle.pathsForResources(ofType: "json", inDirectory: nil).flatMap { MKExercisePlan(file: URL(fileURLWithPath: $0)) }
    }
    
    ///
    /// the list of predefined exercise plans
    ///
    var predefinedSessionTypes: [MRSessionType] {
        return exercisePlans.map { .predefined(plan: $0) }
    }
    
    ///
    /// The default exercise plan
    ///
    private var defaultSessionType: MRSessionType? {
        let bundlePath = Bundle(for: MRAppDelegate.self).pathForResource("Sessions", ofType: "bundle")!
        let bundle = Bundle(path: bundlePath)!
        if let defaultFile = bundle.pathForResource("test_workout", ofType: "json"),
            let plan = MKExercisePlan(file: URL(fileURLWithPath: defaultFile)) {
            return .predefined(plan: plan)
        }
        return nil
    }
    
    ///
    /// the ordered list of the upcoming sessions
    /// (when no workouts have been recorded the returned list contains only the default workout plan)
    ///
    var sessionTypes: [MRSessionType] {
        let userPlans = sessionPlan.next.flatMap { MRManagedExercisePlan.planForId($0, location: currentLocation, inManagedObjectContext: managedObjectContext) }
        
        if userPlans.isEmpty, let defaultPlan = defaultSessionType {
            // user has not started any workout yet, return the default plan
            return [defaultPlan]
        }
        
        return userPlans.map { .userDefined(plan: $0) }
    }
    
    ///
    /// Returns the list of achievements for the given session type
    ///
    func achievementsForSessionType(_ sessionType: MRSessionType) -> [MRAchievement] {
        switch sessionType {
        case .userDefined(let plan):
            return MRManagedAchievement.fetchAchievementsForPlan(plan, inManagedObjectContext: managedObjectContext).map { $0.name }
        default:
            return []
        }
    }
    
    // MARK: - Core Location stack
    
    private func updatedLocation(_ location: CLLocation) {
        currentLocation = MRManagedLocation.findAtLocation(location.coordinate, inManagedObjectContext: managedObjectContext)
        if let currentLocation = currentLocation {
            currentLocationExerciseDetails = currentLocation.managedExercises.flatMap { le in
                guard let detail = baseExerciseDetails.filter({ $0.id == le.id }).first else { return nil }
                let labels = detail.labels ?? []
                let muscle = detail.muscle
                return MKExerciseDetail(id: le.id, type: detail.type, muscle: muscle, labels: labels, properties: le.properties)
            }
            exerciseDetails =
                currentLocationExerciseDetails +
                baseExerciseDetails.filter { bed in
                    return !currentLocationExerciseDetails.contains { ced in
                        return ced.id == bed.id
                    }
                }
        } else {
            exerciseDetails = baseExerciseDetails
        }
        
        NotificationCenter.default().post(name: Notification.Name(rawValue: MRNotifications.LocationDidObtain.rawValue), object: locationName)
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        updatedLocation(locations.last!)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: NSError) {
        #if (arch(i386) || arch(x86_64)) && os(iOS)
            let location = CLLocation(latitude: CLLocationDegrees(53.435739), longitude: CLLocationDegrees(-2.165993))
            updatedLocation(location)
        #endif
    }
    
    // MARK: - Core Data stack
    
    lazy var applicationDocumentsDirectory: URL = {
        // The directory the application uses to store the Core Data store file. This code uses a directory named "io.muvr.CDemo" in the application's documents Application Support directory.
        let urls = FileManager.default().urlsForDirectory(.documentDirectory, inDomains: .userDomainMask)
        return urls.first!
    }()
    
    lazy var managedObjectModel: NSManagedObjectModel = {
        // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
        let modelURL = Bundle.main().urlForResource("Muvr", withExtension: "momd")!
        return NSManagedObjectModel(contentsOf: modelURL)!
    }()
    
    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        // The persistent store coordinator for the application. This implementation creates and returns a coordinator, having added the store for the application to it. This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
        // Create the coordinator and store
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = try! self.applicationDocumentsDirectory.appendingPathComponent("MuvrCoreData.sqlite")
        var failureReason = "There was an error creating or loading the application's saved data."
        do {
            try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: url, options: nil)
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
        var managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
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
