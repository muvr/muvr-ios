import Foundation

public struct MKExerciseSession {
    /// the session id
    public let id: String
    /// the model id
    public let exerciseModelId: MKExerciseModelId
    /// the start timestamp
    public let startDate: NSDate
    
    ///
    /// Constructs this instance from the values in ``exerciseConnectivitySession``
    ///
    /// - parameter exerciseConnectivitySession: the connectivity session
    ///
    init(exerciseConnectivitySession: MKExerciseConnectivitySession) {
        self.id = exerciseConnectivitySession.id
        self.exerciseModelId = exerciseConnectivitySession.exerciseModelId
        self.startDate = exerciseConnectivitySession.startDate
    }
        
}
