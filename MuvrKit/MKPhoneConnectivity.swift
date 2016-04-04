public protocol MKPhoneConnectivity {

    ///
    /// Tells the watch to start the given session
    ///
    func startSession(session: MKExerciseSession)
    
    
    ///
    /// Tells the watch to end the given session
    ///
    func endSession(session: MKExerciseSession)

}
