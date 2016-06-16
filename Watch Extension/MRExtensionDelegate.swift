import WatchKit
import WatchConnectivity
import MuvrKit

struct MRNotifications {
    static let currentSessionDidStart: NSNotification.Name = NSNotification.Name("currentSessionDirStart")
    static let currentSessionDidEnd: NSNotification.Name   = NSNotification.Name("currentSessionDirEnd")
}

class MRExtensionDelegate : NSObject, WKExtensionDelegate, MKExerciseSessionConnectivityDelegate {
    private lazy var connectivity: MKConnectivity = {
        return MKConnectivity(delegate: self)
    }()
    
    private lazy var workoutDelegate: MRWorkoutSessionDelegate = {
        return MRWorkoutSessionDelegate()
    }()
    
    ///
    /// Convenience method that returns properly typed reference to this instance
    ///
    /// - returns: ``MRExtensionDelegate`` instance
    ///
    static func sharedDelegate() -> MRExtensionDelegate {
        return WKExtension.shared().delegate! as! MRExtensionDelegate
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
    func startSession(_ exerciseType: MKExerciseType) {
        connectivity.startSession(exerciseType)
    }
    
    ///
    /// Ends the session
    ///
    func endLastSession() {
        connectivity.endLastSession()
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
    
    /// MARK: MKMetadataConnectivityDelegate
    
    func sessionStarted(_ session: (MKExerciseSession, MKExerciseSessionProperties)) {
        let (s, p) = session
        workoutDelegate.startSession(start: p.start, exerciseType: s.exerciseType)
        NotificationCenter.default().post(name: MRNotifications.currentSessionDidStart, object: s.id)
    }
    
    func sessionEnded(_ session: (MKExerciseSession, MKExerciseSessionProperties)) {
        let (s, p) = session
        workoutDelegate.stopSession(end: p.end ?? Date())
        NotificationCenter.default().post(name: MRNotifications.currentSessionDidEnd, object: s.id)
    }
    
}
