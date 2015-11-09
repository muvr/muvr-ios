import WatchKit
import CoreMotion
import WatchConnectivity

///
/// Collects statistics about the current exercise session
///
public struct MKExerciseSessionStats {
    
    /// Sample counter struct
    public struct SampleCounter {
        public var recorded: Int = 0
        public var sent: Int = 0
    }
    
    public var batchCounter: SampleCounter = SampleCounter()
    public var realTimeCounter: SampleCounter?

}

///
/// Tracks the data sent and session end date
///
public struct MKExerciseSessionProperties {
    public let start: NSDate // session start date
    public let accelerometerStart: NSDate?
    public let end: NSDate?
    public let recorded: Int
    public let sent: Int
    
    /// Indicates whether the props represent ended session
    internal var ended: Bool {
        return end != nil
    }
    
    /// Copies this instance assigning the ``end`` field
    internal func with(end end: NSDate) -> MKExerciseSessionProperties {
        return MKExerciseSessionProperties(start: start, accelerometerStart: accelerometerStart, end: end, recorded: recorded, sent: sent)
    }
    
    /// Copies this instance incrementing the ``recorded`` field.
    internal func with(recorded rd: Int) -> MKExerciseSessionProperties {
        // new recorded value is send + rd (because all recorded samples might not have been sent)
        return MKExerciseSessionProperties(start: start, accelerometerStart: accelerometerStart, end: end, recorded: sent + rd, sent: sent)
    }
    
    /// Copies this instance assigning the ``accelerometerStart`` field and incrementing the ``sent`` field.
    internal func with(accelerometerStart accelerometerStart: NSDate) -> MKExerciseSessionProperties {
        // compute sent samples based on ``accelerometerStart`` - count missing samples as sent
        let sent = Int(accelerometerStart.timeIntervalSinceDate(start)) * 50
        return MKExerciseSessionProperties(start: start, accelerometerStart: accelerometerStart, end: end, recorded: recorded, sent: sent)
    }
    
    /// Indicates the session duration
    /// if the session is not over it indicates the elpased time since session start
    public var duration: NSTimeInterval {
        let end = self.end ?? NSDate()
        return end.timeIntervalSinceDate(start)
    }
    
    /// Indicates whether the props represent completed session
    internal var completed: Bool {
        // a session is completed when ended and all data sent over
        return ended && end!.timeIntervalSinceDate(accelerometerStart!) < 8.0 // it's ok to miss the last window
    }
}

///
/// Session metadata; when transferred to the mobile counterpart, this is everything that's
/// needed to then process the data files.
///
public struct MKExerciseSession: Hashable, Equatable {
    /// the session identity
    let id: String
    /// the start date
    public let start: NSDate
    /// indicates that this is a demo session
    public let demo: Bool
    /// the model id
    public let modelId: MKExerciseModelId
    
    /// implmenetation of Hashable.hashValue
    public var hashValue: Int {
        get {
            return id.hashValue
        }
    }
    
}

///
/// Implementation of Equatable for MKExerciseSession
///
public func ==(lhs: MKExerciseSession, rhs: MKExerciseSession) -> Bool {
    return lhs.id == rhs.id
}

