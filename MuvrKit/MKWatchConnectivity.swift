import Foundation
import CoreMotion
import WatchConnectivity

///
/// Default settings for the connectivity componentry
///
struct MKConnectivitySettings {
    // the ``CMSensorRecorder`` samples at 50 Hz
    static let samplingRate = 50
    // all classifiers work with windows of 400 samples; i.e. 8 seconds.
    static let windowSize = 400
    // the convenience mapping of the # samples to wall time
    static let windowDuration: TimeInterval = TimeInterval(windowSize) / TimeInterval(samplingRate)
    
    ///
    /// Computes the number of samples for the given ``duration``.
    /// - parameter duration: the required duration in seconds
    /// - returns: the number of samples
    ///
    static func samplesForDuration(_ duration: TimeInterval) -> Int {
        return Int(duration * Double(samplingRate))
    }
}

///
/// Maintains all connectivity sessions
///
struct MKConnectivitySessions {
    
    private var sessions: [MKExerciseSession: MKExerciseSessionProperties]
    
    /// Used to persist the sessions in case of app shut down before session stopped
    private static let fileUrl = "\(NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!)/sessions.json"
    
    init() {
        self.sessions = MKConnectivitySessions.loadSessions()
    }
    
    ///
    /// Updates the session props with the result of applying ``propsUpdate`` to the session's props
    /// - parameter session: the session to update
    /// - parameter propsUpdate: the function that returns updated props given the old ones
    ///
    mutating func update(_ session: MKExerciseSession, propsUpdate: (MKExerciseSessionProperties) -> MKExerciseSessionProperties) -> MKExerciseSessionProperties? {
        if let oldProps = sessions[session] {
            let newProps = propsUpdate(oldProps)
            if oldProps.ended && !newProps.ended {
                NSLog("Session resurrection")
                return nil
            }
            sessions[session] = propsUpdate(oldProps)
            saveSessions(sessions)
            return sessions[session]
        }
        return nil
    }
    
    ///
    /// Removes the given ``session``
    /// - parameter session: the session to remove
    ///
    mutating func remove(_ session: MKExerciseSession) {
        sessions.removeValue(forKey: session)
        saveSessions(sessions)
    }
    
    ///
    /// Add a new session
    /// - parameter session: the session to be added
    ///
    mutating func add(_ session: MKExerciseSession, properties: MKExerciseSessionProperties) {
        sessions[session] = properties
        saveSessions(sessions)
    }
    
    /// ``true`` if there are no sessions
    var isEmpty: Bool {
        return sessions.isEmpty
    }
    
    /// The debug description
    var description: String {
        if let (s, p) = mostImportantSessionsEntry {
            return "\(sessions.count): \(s.id.characters.first!): \(p.sent)/\(Int(p.duration) * 50)"
        }
        return "0"
    }
    
    /// The number of sessions
    var count: Int {
        return sessions.count
    }
    
    ///
    /// Returns the most important session for processing, if available
    ///
    var mostImportantSessionsEntry: (MKExerciseSession, MKExerciseSessionProperties)? {
        // the current session or whichever one remains
        return currentSession ?? sessions.first
    }

    ///
    /// Returns the first encountered un-ended session
    ///
    var currentSession: (MKExerciseSession, MKExerciseSessionProperties)? {
        // pick the not-yet-ended session first
        for (session, props) in sessions where !props.ended {
            return (session, props)
        }

        // nothing
        return nil
    }
    
    private func saveSessions(_ sessions: [MKExerciseSession: MKExerciseSessionProperties]) {
        let jsonString = MKConnectivitySessions.serializeSessions(sessions)
        do {
            try jsonString!.write(toFile: MKConnectivitySessions.fileUrl, atomically: true, encoding: String.Encoding.utf8)
        } catch let writingFailure {
            NSLog("Error while persisting sessions on the Watch : \(writingFailure)")
        }
    }
    
    private static func loadSessions() -> [MKExerciseSession: MKExerciseSessionProperties] {
        if let fileContent = FileManager.default().contents(atPath: MKConnectivitySessions.fileUrl) {
            let loadedSessions = deserializeSessions(fileContent)
            NSLog("Found \(loadedSessions.count) sessions to load on app start")
            return loadedSessions
        } else {
            NSLog("Found 0 sessions to load on app start.")
            return [:]
        }
    }
    
    private static func serializeSessions(_ sessions: [MKExerciseSession: MKExerciseSessionProperties]) -> String? {
        var data = [[String: AnyObject]]()
        for (session, properties) in sessions {
            let sessionData = session.metadata.plus(properties.metadata)
            data.append(sessionData)
        }
        
        do {
            let json = try JSONSerialization.data(withJSONObject: data, options:JSONSerialization.WritingOptions(rawValue: 0))
            return String(data: json, encoding: String.Encoding.utf8)
        } catch let serializationFailure {
            NSLog("Error while serializing a session : \(serializationFailure)")
            return nil
        }
    }
    
    private static func deserializeSessions(_ data: Data) -> [MKExerciseSession: MKExerciseSessionProperties] {
        var sessions = [MKExerciseSession: MKExerciseSessionProperties]()
        
        do {
            if let sessionsData = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.allowFragments) as? [[String: NSObject]] {
                for sessionDetails in sessionsData {
                    if let session = MKExerciseSession(metadata: sessionDetails),
                       let properties = MKExerciseSessionProperties(metadata: sessionDetails) {
                        sessions[session] = properties
                    }
                }
            } else {
                NSLog("No sessions json found to parse.")
            }
        } catch let serializationFailure {
            NSLog("Error while deserializing sessions : \(serializationFailure)")
        }
        
        return sessions
    }

    
}

///
/// The Watch -> iOS connectivity; deals with the underlying mechanism of data transfer and sensor
/// data recording.
///
/// The main key concept in communication is that it is possible to record multiple sessions even
/// with the counterpart missing. (The data gets lost after 3 days, though.)
///
/// The communication proceeds as follows:
/// - *begin* as simple app message so that the phone can modify its UI if it is
///    reachable at the start of the session.
/// - *file* as file with metadata that contains all information contained in the
///   begin message. This allows the phone to pick up running sessions if it were
///   not reachable at the start.
///
/// Additionally, the *file* message's metadata may include the ``end`` property, which indicates
/// that the file being received is the last file in the session, and that the session should finish.
///
public final class MKConnectivity : NSObject, WCSessionDelegate {
    public typealias OnFileTransferDone = () -> Void

    // the function that will be called when file transfer succeeds. 
    // NB there can be only one outstanding transfer at a time.
    private var onFileTransferDone: OnFileTransferDone?
    
    // the sensor recorder
    private let recorder: CMSensorRecorder = CMSensorRecorder()
    // the required SDTs that the recorder provides
    private let recordedTypes: [MKSensorDataType]
    // the dimensionality of the data
    private let dimension: Int
    // the current sessions
    private var sessions = MKConnectivitySessions()
    // the transfer queue
    private let transferQueue = DispatchQueue(label: "io.muvr.transferQueue", attributes: [DispatchQueueAttributes.serial, DispatchQueueAttributes.qosUserInitiated], target: nil)
    // the delegate receiving session start/stop events
    private let delegate: MKExerciseSessionConnectivityDelegate
    
    public var sessionsCount: Int { get {
            return sessions.count
        }
    }

    ///
    /// Initializes this instance, assigninf the metadata ans sensorData delegates.
    /// This call should only happen once
    ///
    /// -parameter metadata: the metadata delegate
    /// -parameter sensorData: the sensor data delegate
    ///
    public init(delegate: MKExerciseSessionConnectivityDelegate) {
        // TODO: Check whether the watch is on the left or right wrist. For now, assume left.
        recordedTypes = [.accelerometer(location: .leftWrist)]
        dimension = recordedTypes.reduce(0) { r, t in return t.dimension + r }
        self.delegate = delegate
        
        super.init()
        WCSession.default().delegate = self
        WCSession.default().activate()
    }
    
    /// the current session
    public var currentSession: (MKExerciseSession, MKExerciseSessionProperties)? {
        return sessions.currentSession
    }
    
    // pending session (ended session but not yet complete)
    public var pendingSession: (MKExerciseSession, MKExerciseSessionProperties)? {
        return sessions.mostImportantSessionsEntry
    }

    ///
    /// Sends the sensor data ``data`` invoking ``onDone`` when the operation completes. The callee should
    /// check the value of ``SendDataResult`` to see if it should retry the transimssion, or if it can safely
    /// trim the data it has collected so far.
    ///
    /// - parameter data: the sensor data to be sent
    /// - parameter onDone: the function to be executed on completion (success or error)
    ///
    func transferSensorDataBatch(_ fileUrl: URL, session: MKExerciseSession, props: MKExerciseSessionProperties?, onDone: OnFileTransferDone) {
        if onFileTransferDone == nil {
            NSLog("Transferring")
            onFileTransferDone = onDone
            var metadata = session.metadata
            if let props = props { metadata = metadata.plus(props.metadata) }
            metadata["timestamp"] = Date().timeIntervalSinceReferenceDate
            WCSession.default().transferFile(fileUrl, metadata: metadata)
        }
    }
    
    public func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: NSError?) {
        
    }
    
    ///
    /// Callled when session events (start/end) are sent from the phone
    ///
    public func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: AnyObject]) {
        guard let exerciseSession = MKExerciseSession(metadata: userInfo),
            let exerciseProps = MKExerciseSessionProperties(metadata: userInfo) else { return }
        
        if let currentSession = currentSession {
            _ = self.sessions.update(currentSession.0) { return $0.withEnd(accelerometerEnd: Date()) }
            delegate.sessionEnded(currentSession)
        }
        if exerciseProps.end == nil {
            sessions.add(exerciseSession, properties: exerciseProps)
            delegate.sessionStarted((exerciseSession, exerciseProps))
        }
    }
    
    ///
    /// Called when the file transfer completes.
    ///
    public func session(_ session: WCSession, didFinish fileTransfer: WCSessionFileTransfer, error: NSError?) {
        NSLog("Transfer done")
        if let onDone = onFileTransferDone {
            transferQueue.sync {
                onDone()
                self.onFileTransferDone = nil
            }
        }
    }
    
    ///
    /// Ends the current session
    ///
    public func endLastSession() {
        guard let lastSession = self.sessions.currentSession else { return }
        delegate.sessionEnded(lastSession)
        
        transferQueue.sync {
            let (session, _) = lastSession
            let endedProps = self.sessions.update(session) { return $0.withEnd(accelerometerEnd: Date()) }
            // Notify phone that session ended
            WCSession.default().transferUserInfo(session.metadata.plus(endedProps?.metadata ?? [:]))
            // still try to send remaining data
            self.innerExecute()
        }
    }
    
    ///
    /// *** THIS FUNCTION SHOULD ONLY BE CALLED ON THE ``transferQueue``. ***
    ///
    /// Performs all the work to encode the samples and transfer to the phone
    ///
    /// *** THIS FUNCTION SHOULD ONLY BE CALLED ON THE ``transferQueue``. ***
    ///
    private func innerExecute() {
        
        let documentsUrl = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true).first!
        let fileUrl = try! URL(fileURLWithPath: documentsUrl).appendingPathComponent("sensordata.raw")
        
        ///
        /// Encodes all the samples between ``from`` and ``to``. 
        /// - parameter from: the starting date
        /// - parameter to: the session end date (if unknown tries to get the data up to now)
        /// - returns: tuple of :
        ///      - URL containing the encoded data
        ///      - date of last encoded sample
        ///      - flag indicating if it's the last chunk of data
        ///
        func encodeSamples(_ from: Date, to: Date?) -> (URL, Date, Bool)? {
            // Indicates if the expected sample is in the requested range
            func isAfterFromDate(_ sample: CMRecordedAccelerometerData) -> Bool {
                return from.timeIntervalSinceReferenceDate <= sample.startDate.timeIntervalSinceReferenceDate
            }

            do {
                try FileManager.default().removeItem(at: fileUrl)
            } catch {
                // Possible failure expected
            }
            
            // try to get the data from the recorder up to now
            // even if the end date is set we want to see if there is data after it
            guard let sdl = recorder.accelerometerData(from: from, to: Date()) else {
                NSLog("No data available.")
                return nil
            }
            
            var encoder: MKSensorDataEncoder? = nil
            var lastChunk = false
            
            // enumerate, creating output only if needed
            for(_, e) in sdl.enumerated() {
                // If data before range, ignore it
                if let data = e as? CMRecordedAccelerometerData where isAfterFromDate(data) {
                    if encoder == nil {
                        encoder = MKSensorDataEncoder(target: MKFileSensorDataEncoderTarget(fileUrl: fileUrl), types: recordedTypes, samplesPerSecond: 50)
                    }
                    // If data after range, no need to go farther 
                    //   -> this is the last chunk for this session
                    if let to = to where data.startDate.timeIntervalSince(to) > 0 {
                        lastChunk = true
                        break
                    }
                    // append data to the encoder
                    encoder!.append([Float(data.acceleration.x), Float(data.acceleration.y), Float(data.acceleration.z)], sampleDate: data.startDate)
                }
            }
            // after the loop, check if we have anything to transmit
            if let encoder = encoder where lastChunk || encoder.duration > MKConnectivitySettings.windowDuration {
                encoder.close()
                if encoder.duration > 0 {
                    NSLog("Written \(encoder.startDate!) - \(encoder.endDate!) samples.")
                }
                return (fileUrl, (encoder.endDate ?? from) as Date, lastChunk)
            }            
            return nil
        }
        
        ///
        /// We process the first session in our ``sessions`` map; if the sensor data is accessible
        /// we will transmit the data to the counterpart. If, as a result of processing this session,
        /// we remove it, we move on to the next session.
        ///
        func processFirstSession() {
            // don't start again 
            if onFileTransferDone != nil {
                NSLog("Still transferring. Skipping new transfer.")
                return
            }
            
            // pick the most important entry
            guard let (session, props) = sessions.mostImportantSessionsEntry else {
                NSLog("No session")
                return
            }
                        
            // compute the dates
            let from = props.accelerometerStart ?? props.start
            let to = props.end ?? Date()
            
            // drop if older than 3 days
            if Date().timeIntervalSince(from) > 60 * 24 * 3 {
                sessions.remove(session)
                return
            }
            
            if (!props.ended && to.timeIntervalSince(from) < MKConnectivitySettings.windowDuration) {
                NSLog("Skip transfer for chunk smaller than a single window")
                return
            }
            
            guard let (fileUrl, end, lastChunk) = encodeSamples(from, to: props.end) else {
                NSLog("No sensor data in \(from) - \(to)")
                return
            }
            
            // update the number of recorded samples
            let updatedProps = sessions.update(session) { return $0.withEnd(accelerometerEnd: end).withCompleted(completed: lastChunk) }
            
            // transfer what we have so far
            transferSensorDataBatch(fileUrl, session: session, props: updatedProps) {
                // set the expected range of samples on the next call
                let finalProps = self.sessions.update(session) { return $0.withStart(accelerometerStart: end) }
                NSLog("Transferred \(finalProps)")
                
                // Remove session if it was the last chunk of data
                if lastChunk {
                    NSLog("Removed \(finalProps)")
                    self.sessions.remove(session)
                    // we're done with this session, we can move on to the next one
                    processFirstSession()
                }
            }
        }
        
        // ask the SDR to record for another 12 hours just in case.
        recorder.recordAccelerometer(forDuration: 43200)
        
        // check whether there is something to be done at all.
        NSLog("beginTransfer(); |sessions| = \(sessions.count)")
        if sessions.isEmpty {
            NSLog("Reachable; no active sessions.")
            return
        }
        
        // TODO: It would be nice to be able to flush the sensor data recorder
        // recorder.flush()
        processFirstSession()
    }
    
    ///
    /// Implements the protocol for the W -> P communication by collecting the data from the sensor recorder,
    /// constructing the messages and dealing with session clean-up.
    ///
    public func execute() {
        transferQueue.sync(execute: innerExecute)
    }

        
    ///
    /// Starts the exercise session with the given ``modelId`` and ``demo`` mode. In demo mode,
    /// the caller should explicitly call ``transferDemoSensorDataForCurrentSession``.
    ///
    /// - parameter modelId: the model id so that the phone can properly classify the data
    ///
    public func startSession(_ exerciseType: MKExerciseType) {
        let session = MKExerciseSession(id: UUID().uuidString, exerciseType: exerciseType)
        let properties = MKExerciseSessionProperties(start: Date())
        sessions.add(session, properties: properties)
        delegate.sessionStarted((session, properties))
        WCSession.default().transferUserInfo(session.metadata.plus(properties.metadata))
    }
    
    /// the description
    public override var description: String {
        return sessions.description
    }
    
}

///
/// Convenience addition to ``[K:V]``
///
private extension Dictionary {
    
    ///
    /// Returns a new ``[K:V]`` by appending ``dict``
    ///
    /// - parameter dict: the dictionary to append
    /// - returns: self + dict
    ///
    func plus(_ dict: [Key : Value]) -> [Key : Value] {
        var result = self
        for (k, v) in dict {
            result.updateValue(v, forKey: k)
        }
        return result
    }
    
}

///
/// Adds the ``metadata`` property that can be used in P -> W comms
/// See ``MKExerciseConnectivitySession`` for the phone counterpart.
///
private extension MKExerciseSession {

    var metadata: [String : AnyObject] {
        return [
            "id" : id,
            "exerciseType": exerciseType.metadata
        ]
    }
    
    //let start = ((metadata["start"] as? NSTimeInterval).map { NSDate(timeIntervalSinceReferenceDate: $0) })
    
    init?(metadata: [String: AnyObject]) {
        if let id = metadata["id"] as? String,
           let exerciseTypeMetadata = metadata["exerciseType"] as? [String : AnyObject],
           let exerciseType = MKExerciseType(metadata: exerciseTypeMetadata) {
           self.init(id: id, exerciseType: exerciseType)
        } else {
            return nil
        }
        
    }
}

///
/// Adds the ``metadata`` property that can be used in P -> W comms
/// See ``MKExerciseConnectivitySession`` for the phone counterpart.
///
private extension MKExerciseSessionProperties {
    
    var metadata: [String : AnyObject] {
        var md: [String : AnyObject] = [:]
        if let end = end { md["end"] = end.timeIntervalSinceReferenceDate }
        if completed { md["last"] = true }
        md["start"] = self.start.timeIntervalSinceReferenceDate
        md["accelerometerStart"] = self.accelerometerStart?.timeIntervalSinceReferenceDate
        md["accelerometerEnd"] = self.accelerometerEnd?.timeIntervalSinceReferenceDate
        return md
    }
    
    init?(metadata: [String: AnyObject]) {
        let accStart = (metadata["accelerometerStart"] as? TimeInterval).map { Date(timeIntervalSinceReferenceDate: $0) }
        let accEnd = (metadata["accelerometerEnd"] as? TimeInterval).map { Date(timeIntervalSinceReferenceDate: $0) }
        let end = (metadata["end"] as? TimeInterval).map { Date(timeIntervalSinceReferenceDate: $0) }
        if let start = ((metadata["start"] as? TimeInterval).map { Date(timeIntervalSinceReferenceDate: $0) }) {
            self.init(start: start, accelerometerStart: accStart, accelerometerEnd: accEnd, end: end, completed: false)
        } else {
            return nil
        }
    }
    
}

///
/// Allows the ``CMSensorDataList`` to be iterated over; unfortunately, the iteration
/// is not specifically-typed.
///
extension CMSensorDataList : Sequence {
    
    public func makeIterator() -> NSFastEnumerationIterator {
        return NSFastEnumerationIterator(self)
    }
}
