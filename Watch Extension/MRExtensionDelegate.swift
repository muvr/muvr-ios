import WatchKit
import WatchConnectivity
import MuvrKit

enum MRNotifications: String {
    case CurrentSessionDidStart
    case CurrentSessionDidEnd
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
    func startSession(exerciseType: MKExerciseType) {
        connectivity.startSession(exerciseType)
        workoutDelegate.startSession(start: NSDate(), exerciseType: exerciseType)
    }
    
    ///
    /// Ends the session
    ///
    func endLastSession() {
        connectivity.endLastSession()
        workoutDelegate.stopSession(end: currentSession?.1.end ?? NSDate())
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
    
    func sessionStarted(session: (MKExerciseSession, MKExerciseSessionProperties)) {
        let (s, p) = session
        guard let currentSession = currentSession where currentSession.0 == s else { return }
        workoutDelegate.startSession(start: p.start, exerciseType: s.exerciseType)
        NSNotificationCenter.defaultCenter().postNotificationName(MRNotifications.CurrentSessionDidStart.rawValue, object: s.id)
    }
    
    func sessionEnded(session: (MKExerciseSession, MKExerciseSessionProperties)) {
        let (s, p) = session
        guard let currentSession = currentSession where currentSession.0 == s else { return }
        workoutDelegate.stopSession(end: p.end!)
        NSNotificationCenter.defaultCenter().postNotificationName(MRNotifications.CurrentSessionDidEnd.rawValue, object: s.id)
    }
    
}
