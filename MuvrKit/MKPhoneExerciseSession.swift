import Foundation

public struct MKExerciseSession {
    /// the session id
    public let id: String
    /// the model id
    public let exerciseModelId: MKExerciseModelId
    /// the start timestamp
    public let start: NSDate
    /// the end timestamp
    public let end: NSDate?
    /// the completed flag
    public let completed: Bool
    
    /// The offset of the last classified exercises
    internal var classificationStart: NSTimeInterval = 0
    
    public init(exerciseModelId: MKExerciseModelId) {
        self.id = NSUUID().UUIDString
        self.exerciseModelId = exerciseModelId
        self.start = NSDate()
        self.end = nil
        self.completed = false
    }
    
    ///
    /// Constructs this instance from the values in ``exerciseConnectivitySession``
    ///
    /// - parameter exerciseConnectivitySession: the connectivity session
    ///
    init(exerciseConnectivitySession: MKExerciseConnectivitySession) {
        self.id = exerciseConnectivitySession.id
        self.exerciseModelId = exerciseConnectivitySession.exerciseModelId
        self.start = exerciseConnectivitySession.start
        self.end = exerciseConnectivitySession.end
        self.completed = exerciseConnectivitySession.last
    }
        
}
