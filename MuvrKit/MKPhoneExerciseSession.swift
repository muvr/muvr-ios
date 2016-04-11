import Foundation

public struct MKExerciseSession {
    /// the session id
    public let id: String
    /// the start timestamp
    public let start: NSDate
    /// the end timestamp
    public let end: NSDate?
    /// the completed flag
    public let completed: Bool
    /// the exercise type
    public let exerciseType: MKExerciseType
    
    public init(exerciseType: MKExerciseType) {
        self.id = NSUUID().UUIDString
        self.start = NSDate()
        self.end = nil
        self.completed = false
        self.exerciseType = exerciseType
    }
    
    ///
    /// Constructs this instance from the values in ``exerciseConnectivitySession``
    ///
    /// - parameter exerciseConnectivitySession: the connectivity session
    ///
    init(exerciseConnectivitySession: MKExerciseConnectivitySession) {
        self.id = exerciseConnectivitySession.id
        self.start = exerciseConnectivitySession.start
        self.end = exerciseConnectivitySession.end
        self.completed = exerciseConnectivitySession.last
        self.exerciseType = exerciseConnectivitySession.exerciseType
    }
    
    ///
    /// Constructs this instance by passing in all its parameters
    /// Allows to extend MKExerciseSession initialisers outside of MuvrKit
    ///
    public init(id: String, start: NSDate, end: NSDate?, completed: Bool, exerciseType: MKExerciseType) {
        self.id = id
        self.start = start
        self.end = end
        self.completed = completed
        self.exerciseType = exerciseType
    }
        
}
