import UIKit
import HealthKit
import MuvrKit

@UIApplicationMain
class MRAppDelegate: UIResponder, UIApplicationDelegate, MKExerciseModelSource, MKExerciseSessionStore, MKSessionClassifierDelegate {
    
    var window: UIWindow?
    
    private var connectivity: MKConnectivity!
    private var classifier: MKSessionClassifier!
    private var exerciseSessions: [MKExerciseSession] = []
    private var currentSession: MKExerciseSession?
    
    var exerciseSessionStoreDelegate: MKExerciseSessionStoreDelegate?
    
    ///
    /// Returns this shared delegate
    ///
    static func sharedDelegate() -> MRAppDelegate {
        return UIApplication.sharedApplication().delegate as! MRAppDelegate
    }

    private func registerSettingsAndDelegates() {
        let settings = UIUserNotificationSettings(forTypes: [UIUserNotificationType.Alert, UIUserNotificationType.Badge, UIUserNotificationType.Sound], categories: nil)
        UIApplication.sharedApplication().registerUserNotificationSettings(settings)
    }
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // set up the classification and connectivity
        classifier = MKSessionClassifier(exerciseModelSource: self, delegate: self)
        connectivity = MKConnectivity(sensorDataConnectivityDelegate: classifier, exerciseConnectivitySessionDelegate: classifier)
        
        
        let typesToShare: Set<HKSampleType> = [HKSampleType.workoutType()]
        let typesToRead: Set<HKSampleType> = [HKSampleType.quantityTypeForIdentifier(HKQuantityTypeIdentifierHeartRate)!]

        HKHealthStore().requestAuthorizationToShareTypes(typesToShare, readTypes: typesToRead) { (x, y) -> Void in
            print(x)
            print(y)
        }

        // notifications et al
        registerSettingsAndDelegates()
        
        // main initialization
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        window = UIWindow(frame: UIScreen.mainScreen().bounds)
        window!.makeKeyAndVisible()
        window!.rootViewController = storyboard.instantiateInitialViewController()
                
        return true
    }
    
    func getAllSessions() -> [MKExerciseSession] {
        return exerciseSessions
    }
    
    func getCurrentSession() -> MKExerciseSession? {
        return currentSession
    }
    
    func getExerciseModel(id id: MKExerciseModelId) -> MKExerciseModel {
        // setup the classifier
        let bundlePath = NSBundle.mainBundle().pathForResource("Models", ofType: "bundle")!
        let data = NSData(contentsOfFile: NSBundle(path: bundlePath)!.pathForResource("demo", ofType: "raw")!)!
        let model = MKExerciseModel(layerConfig: [1200, 250, 100, 3], weights: data,
            sensorDataTypes: [.Accelerometer(location: .LeftWrist)],
            exerciseIds: ["biceps-curl", "lateral-raise", "triceps-extension"],
            minimumDuration: 8)
        return model
    }
    
    func sessionClassifierDidEnd(session: MKExerciseSession) {
        currentSession = session
        if let delegate = exerciseSessionStoreDelegate {
            delegate.exerciseSessionStoreChanged(self)
        }
    }
    
    func sessionClassifierDidSummarise(session: MKExerciseSession) {
        currentSession = nil
        exerciseSessions.append(session)
        if let delegate = exerciseSessionStoreDelegate {
            delegate.exerciseSessionStoreChanged(self)
        }
    }
    
    func sessionClassifierDidClassify(session: MKExerciseSession) {
        currentSession = session
        if let delegate = exerciseSessionStoreDelegate {
            delegate.exerciseSessionStoreChanged(self)
        }
    }
    
    func sessionClassifierDidStart(session: MKExerciseSession) {
        currentSession = session
        if let delegate = exerciseSessionStoreDelegate {
            delegate.exerciseSessionStoreChanged(self)
        }
    }
}
