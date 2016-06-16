///
/// A protocal representing the messages the phone needs to send to the connected wearable
/// This protocol needs to be implemented for every supported device: 
/// Currently: Apple Watch and Pebble
///
public protocol MKDeviceConnectivity {

    ///
    /// Tells the watch to start the given session
    /// - parameter session: the session to start
    ///
    func startSession(_ session: MKExerciseSession)
    
    
    ///
    /// A callback to report the current exercise
    ///
    func exerciseStarted(_ exercise: MKExerciseDetail, start: Date)
    
    ///
    /// Tells the watch to end the given session
    /// - parameter session: the session to end
    ///
    func endSession(_ session: MKExerciseSession)
    
    
    ///
    /// Indicates if the watch is reachable 
    /// (i.e. there is a communication established between the phone and the watch)
    ///
    var reachable: Bool { get }

}
