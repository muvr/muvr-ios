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
    public let start: Date // session start date
    public let accelerometerStart: Date?
    public let accelerometerEnd: Date?
    public let end: Date?
    public let completed: Bool
    
    public init(start: Date) {
        self.start = start
        self.accelerometerStart = nil
        self.accelerometerEnd = nil
        self.end = nil
        self.completed = false
    }
    
    public init(start: Date, accelerometerStart: Date?, accelerometerEnd: Date?, end: Date?, completed: Bool) {
        self.start = start
        self.accelerometerStart = accelerometerStart
        self.accelerometerEnd = accelerometerEnd
        self.end = end
        self.completed = completed
    }
    
    /// Indicates whether the props represent ended session
    internal var ended: Bool {
        return end != nil
    }
    
    /// Copies this instance assigning the ``end`` field
    internal func with(end: NSDate) -> MKExerciseSessionProperties {
        return MKExerciseSessionProperties(start: start, accelerometerStart: accelerometerStart, accelerometerEnd: accelerometerEnd, end: end, completed: completed)
    }
    
    /// Copies this instance assigning the ``completed`` field
    internal func with(completed: Bool) -> MKExerciseSessionProperties {
        return MKExerciseSessionProperties(start: start, accelerometerStart: accelerometerStart, accelerometerEnd: accelerometerEnd, end: end, completed: completed)
    }
    
    /// Copies this instance assigning the ``accelerometerEnd`` field.
    internal func with(accelerometerEnd: NSDate) -> MKExerciseSessionProperties {
        // new recorded value is send + rd (because all recorded samples might not have been sent)
        return MKExerciseSessionProperties(start: start, accelerometerStart: accelerometerStart, accelerometerEnd: accelerometerEnd, end: end, completed: completed)
    }
    
    /// Copies this instance assigning the ``accelerometerStart`` field
    internal func with(accelerometerStart: NSDate) -> MKExerciseSessionProperties {
        return MKExerciseSessionProperties(start: start, accelerometerStart: accelerometerStart, accelerometerEnd: accelerometerEnd, end: end, completed: completed)
    }
    
    /// Indicates the session duration
    /// if the session is not over it indicates the elpased time since session start
    public var duration: TimeInterval {
        let end = self.end ?? Date()
        return end.timeIntervalSinceDate(start)
    }
    
    /// Indicates the number of recorded samples
    public var recorded: Int {
        return accelerometerEnd.map { Int($0.timeIntervalSinceDate(start)) * MKConnectivitySettings.samplingRate } ?? 0
    }
    
    /// Indicates the number of sent samples
    public var sent: Int {
        return accelerometerStart.map { Int($0.timeIntervalSinceDate(start)) * MKConnectivitySettings.samplingRate } ?? 0
    }
}

///
/// Session metadata; when transferred to the mobile counterpart, this is everything that's
/// needed to then process the data files.
///
public struct MKExerciseSession: Hashable, Equatable {
    /// the session identity
    public let id: String
    /// the exercise type
    public let exerciseType: MKExerciseType
    
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

