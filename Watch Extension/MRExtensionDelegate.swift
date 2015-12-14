import WatchKit
import WatchConnectivity
import MuvrKit

class MRExtensionDelegate : NSObject, WKExtensionDelegate, MKMetadataConnectivityDelegate {
    private lazy var connectivity: MKConnectivity = {
        return MKConnectivity(delegate: self)
    }()
    
    private lazy var workoutDelegate: MRWorkoutSessionDelegate = {
        return MRWorkoutSessionDelegate()
    }()
    
    /// Used to persist the models
    private static let fileUrl = "\(NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true).first!)/models.json"
    
    private(set) internal var exerciseModelMetadata: [MKExerciseModelMetadata] = MRExtensionDelegate.loadModelsMetadata()

    ///
    /// Convenience method that returns properly typed reference to this instance
    ///
    /// - returns: ``MRExtensionDelegate`` instance
    ///
    static func sharedDelegate() -> MRExtensionDelegate {
        return WKExtension.sharedExtension().delegate! as! MRExtensionDelegate
    }
    
    /// The current session
    var currentSession: (MKExerciseSession, MKExerciseSessionProperties)? {
        return connectivity.currentSession
    }
    
    /// The pending session
    var pendingSession: (MKExerciseSession, MKExerciseSessionProperties)? {
        return connectivity.pendingSession
    }
    
    /// The description
    override var description: String {
        return connectivity.description
    }
    
    /// The number of session on the watch
    var sessionsCount: Int {
        return connectivity.sessionsCount
    }
    
    var heartrate: Double? {
        return workoutDelegate.heartrate
    }
    var energyBurned: Double? {
        return workoutDelegate.energyBurned
    }
    
    ///
    /// Starts the session
    ///
    func startSession(exerciseModelMetadataIndex exerciseModelMetadataIndex: Int, demo: Bool) {
        let (modelId, _) = exerciseModelMetadata[exerciseModelMetadataIndex]
        connectivity.startSession(modelId, demo: demo)
        workoutDelegate.startSession(start: NSDate(), model: modelId)
    }
    
    ///
    /// Ends the session
    ///
    func endLastSession() {
        connectivity.endLastSession()
        workoutDelegate.stopSession(end: currentSession?.1.end ?? NSDate())
    }
    
    func sendSamples(fileUrl: NSURL) {
        connectivity.transferDemoSensorDataForCurrentSession(fileUrl)
    }
    
    func applicationDidFinishLaunching() {
        connectivity = MKConnectivity(delegate: self)
        workoutDelegate.authorise()
    }
    
    func applicationDidBecomeActive() {
        connectivity.execute()
    }

    func applicationWillResignActive() {

    }
    
    // MARK: MKMetadataConnectivityDelegate

    func metadataConnectivityDidReceiveExerciseModelMetadata(exerciseModelMetadata: [MKExerciseModelMetadata]) {
        self.exerciseModelMetadata = exerciseModelMetadata
        MRExtensionDelegate.saveModelsMetadata(exerciseModelMetadata)
    }
    
    static func loadModelsMetadata() -> [MKExerciseModelMetadata] {
        if let data = NSFileManager.defaultManager().contentsAtPath(MRExtensionDelegate.fileUrl) {
            do {
                let jsonObj = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments) as? [String: String]
                if let jsonObj = jsonObj {
                    let models = jsonObj.map { (id, name) -> MKExerciseModelMetadata in return (id, name) }
                    NSLog("Loaded \(models.count) models")
                    return models
                }
            } catch let error {
                NSLog("Error while deserializing models metadata : \(error)")
            }
        }
        return []
    }
    
    static func saveModelsMetadata(models: [MKExerciseModelMetadata]) {
        let jsonObj = NSMutableDictionary()
        models.forEach { id, name in
        jsonObj[id] = name
        }
        do {
            let data = try NSJSONSerialization.dataWithJSONObject(jsonObj, options:NSJSONWritingOptions(rawValue: 0))
            data.writeToFile(MRExtensionDelegate.fileUrl, atomically: true)
            NSLog("Saved \(models.count) models")
        } catch let error {
            NSLog("Error while serializing models metadata : \(error)")
        }
    }

}
