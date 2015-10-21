import UIKit
import HealthKit
import MuvrKit

@UIApplicationMain
class MRAppDelegate: UIResponder, UIApplicationDelegate, MKExerciseModelSource {
    var window: UIWindow?
    private var connectivity: MKConnectivity!
    private var classifier: MKSessionClassifier!
    private var deviceToken: NSData?
    
    func setSessionClassifierDelegate(delegate: MKSessionClassifierDelegate) {
        classifier.delegate = delegate
    }
    
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
        classifier = MKSessionClassifier(exerciseModelSource: self)
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
    
    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
        self.deviceToken = deviceToken
        NSLog("Token \(deviceToken)")
    }
    
    func application(application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: NSError) {
        let data: [UInt8] = [0x5A, 0xB8, 0x48, 0x05, 0xF8, 0xD0, 0xCC, 0x63, 0x0A, 0x89, 0x90, 0xA8, 0x4D, 0x48, 0x08, 0x41, 0xC3, 0x68, 0x40, 0x03, 0x6C, 0x12, 0x2C, 0x8E, 0x52, 0xA8, 0xDC, 0xFD, 0x68, 0xA6, 0xF6, 0xF8]
        let buf = UnsafePointer<[UInt8]>(data)
        let deviceToken = NSData(bytes: buf, length: data.count)
        self.deviceToken = deviceToken
        NSLog("Not registered \(error)")
    }
    
    func application(application: UIApplication, didRegisterUserNotificationSettings notificationSettings: UIUserNotificationSettings) {
        NSLog("settings %@", notificationSettings)
    }
    
    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject]) {
        NSLog("Got remote notification %@", userInfo)
    }
    
    func applicationDidBecomeActive(application: UIApplication) {
        // MRMuvrServer.sharedInstance.setBaseUrlString(MRUserDefaults.muvrServerUrl)
    }
    
    func getExerciseModel(id id: MKExerciseModelId) -> MKExerciseModel {
        fatalError()
    }
}

