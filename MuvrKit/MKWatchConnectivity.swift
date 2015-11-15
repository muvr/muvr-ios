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
    static let windowDuration: NSTimeInterval = NSTimeInterval(windowSize) / NSTimeInterval(samplingRate)
    
    ///
    /// Computes the number of samples for the given ``duration``.
    /// - parameter duration: the required duration in seconds
    /// - returns: the number of samples
    ///
    static func samplesForDuration(duration: NSTimeInterval) -> Int {
        return Int(duration * Double(samplingRate))
    }
}

struct MKConnectivitySessions {
    private var sessions: [MKExerciseSession: MKExerciseSessionProperties] = [:]
    private static let lock: NSObject = NSObject()
    
    mutating func update(session: MKExerciseSession, propsUpdate: MKExerciseSessionProperties -> MKExerciseSessionProperties) {
        objc_sync_enter(MKConnectivitySessions.lock)
        if let oldProps = sessions[session] {
            let newProps = propsUpdate(oldProps)
            if oldProps.ended && !newProps.ended { fatalError("Session resurrection") }
            sessions[session] = propsUpdate(oldProps)
        }
        objc_sync_exit(MKConnectivitySessions.lock)
    }
    
    mutating func update(session: MKExerciseSession, newProps: MKExerciseSessionProperties) {
        objc_sync_enter(MKConnectivitySessions.lock)
        if let oldProps = sessions[session] {
            if oldProps.ended && !newProps.ended { fatalError("Session resurrection") }
            sessions[session] = newProps
        }
        objc_sync_exit(MKConnectivitySessions.lock)
    }
    
    mutating func remove(session: MKExerciseSession) {
        objc_sync_enter(MKConnectivitySessions.lock)
        sessions.removeValueForKey(session)
        objc_sync_exit(MKConnectivitySessions.lock)
    }
    
    mutating func add(session: MKExerciseSession) {
        let props = MKExerciseSessionProperties(start: session.start)
        sessions[session] = props
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
    
    private var onFileTransferDone: OnFileTransferDone?
    internal var transferringRealTime: Bool = false
    
    private let recorder: CMSensorRecorder = CMSensorRecorder()
    // the required SDTs that the recorder provides
    private let recordedTypes: [MKSensorDataType]
    // the dimensionality of the data
    private let dimension: Int
    // the current sessions
    private var sessions = MKConnectivitySessions()
    // the transfer queue
    private let transferQueue = dispatch_queue_create("io.muvr.transferQueue", dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_USER_INITIATED, 0))

    ///
    /// Initializes this instance, assigninf the metadata ans sensorData delegates.
    /// This call should only happen once
    ///
    /// -parameter metadata: the metadata delegate
    /// -parameter sensorData: the sensor data delegate
    ///
    public init(delegate: MKMetadataConnectivityDelegate) {
        // TODO: Check whether the watch is on the left or right wrist. For now, assume left.
        recordedTypes = [.Accelerometer(location: .LeftWrist)]
        dimension = recordedTypes.reduce(0) { r, t in return t.dimension + r }
        
        super.init()
        WCSession.defaultSession().delegate = self
        WCSession.defaultSession().activateSession()
        
        delegate.metadataConnectivityDidReceiveExerciseModelMetadata(defaultExerciseModelMetadata)
    }
    
    /// the current session
    public var currentSession: (MKExerciseSession, MKExerciseSessionProperties)? {
        return sessions.currentSession
    }

    ///
    /// Sends the sensor data ``data`` invoking ``onDone`` when the operation completes. The callee should
    /// check the value of ``SendDataResult`` to see if it should retry the transimssion, or if it can safely
    /// trim the data it has collected so far.
    ///
    /// - parameter data: the sensor data to be sent
    /// - parameter onDone: the function to be executed on completion (success or error)
    ///
    func transferSensorDataBatch(fileUrl: NSURL, session: MKExerciseSession, props: MKExerciseSessionProperties?, onDone: OnFileTransferDone) {
        if onFileTransferDone == nil {
            onFileTransferDone = onDone
            var metadata = session.metadata
            if let props = props { metadata = metadata.plus(props.metadata) }
            metadata["timestamp"] = NSDate().timeIntervalSince1970
            WCSession.defaultSession().transferFile(fileUrl, metadata: metadata)
        }
    }
    
    ///
    /// Transfer sensor data if there is a not-yet-ended demo session
    ///
    /// - parameter sensorData: the sensor data to be transferred
    ///
    public func transferDemoSensorDataForCurrentSession(fileUrl: NSURL) {
        if let (session, props) = sessions.currentSession {
            if session.demo {
                sessions.update(session) { $0.with(accelerometerEnd: NSDate()) }
                transferSensorDataBatch(fileUrl, session: session, props: props) {
                    self.sessions.update(session) { $0.with(accelerometerStart: NSDate()) }
                }
            }
        }
    }
    
    ///
    /// Called when the file transfer completes.
    ///
    public func session(session: WCSession, didFinishFileTransfer fileTransfer: WCSessionFileTransfer, error: NSError?) {
        if let onDone = onFileTransferDone {
            dispatch_async(transferQueue) {
                onDone()
                self.onFileTransferDone = nil
            }
        }
    }
    
    ///
    /// Ends the current session
    ///
    public func endLastSession() {
        if let (session, _) = sessions.currentSession {
            sessions.update(session) { $0.with(end: NSDate()) }
        }
        
        // still try to send remaining data
        execute()
    }
    
    ///
    ///
    ///
    private func innerExecute() {
        
        func encodeSamples(from from: NSDate, to: NSDate, demo: Bool) -> (NSURL, NSDate)? {
            var simulatedSamples = demo
            
            #if (arch(i386) || arch(x86_64))
                simulatedSamples = true
            #endif
            
            let duration = to.timeIntervalSinceDate(from)
            let sampleCount = dimension * MKConnectivitySettings.samplingRate * Int(duration)
            
            // Indicates if the expected sample is in the requested range
            func isInRange(sample: CMRecordedAccelerometerData) -> Bool {
                // check only 'start' time - don't care about end of range
                return from.timeIntervalSince1970 <= sample.startDate.timeIntervalSince1970 &&
                         to.timeIntervalSince1970 >  sample.startDate.timeIntervalSince1970
            }
            
            // Indicates if the sample is the expected one (regarding recorded time)
            // It allows to check for ``missing`` samples in the requested range
            func isExpectedSample(sample: CMRecordedAccelerometerData, lastTime: NSDate?) -> Bool {
                // all samples have to be in range
                if !isInRange(sample) { return false }
                
                // otherwise, the sample has to be less than 40ms from the last one
                if let lastTime = lastTime {
                    // check sample is not more than 40ms apart from last one
                    return sample.startDate.timeIntervalSinceDate(lastTime) < 0.04
                } else {
                    // the first sample we've seen
                    return true
                }
            }
            
            let documentsUrl = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true).first!
            let fileUrl = NSURL(fileURLWithPath: documentsUrl).URLByAppendingPathComponent("sensordata.raw")
            do {
                try NSFileManager.defaultManager().removeItemAtURL(fileUrl)
            } catch {
                //
            }
            
            if simulatedSamples {
                let encoder = MKSensorDataEncoder(target: MKFileSensorDataEncoderTarget(fileUrl: fileUrl), types: recordedTypes, samplesPerSecond: 50)
                let samples = (0..<sampleCount).map { _ in return Float(0) }
                encoder.append(samples)
                encoder.close(0)
                NSLog("Generated \(from) - \(to) samples.")
                return (fileUrl, to)
            } else {
                if let sdl = recorder.accelerometerDataFromDate(from, toDate: to) {
                    var firstSampleTime: NSDate? = nil
                    var lastSampleTime: NSDate? = nil
                    var encoder: MKSensorDataEncoder? = nil
                    sdl.enumerate().forEach { (_, e) in
                        if let data = e as? CMRecordedAccelerometerData where isExpectedSample(data, lastTime: lastSampleTime) {
                            if firstSampleTime == nil { firstSampleTime = data.startDate }
                            if encoder == nil {
                                encoder = MKSensorDataEncoder(target: MKFileSensorDataEncoderTarget(fileUrl: fileUrl), types: recordedTypes, samplesPerSecond: 50)
                            }
                            lastSampleTime = data.startDate
                            encoder!.append([Float(data.acceleration.x), Float(data.acceleration.y), Float(data.acceleration.z)])
                        }
                    }
                    if let firstSampleTime = firstSampleTime, let lastSampleTime = lastSampleTime, let encoder = encoder {
                        let recordedDuration = lastSampleTime.timeIntervalSince1970 - firstSampleTime.timeIntervalSince1970
                        if recordedDuration > 8.0 {
                            encoder.close(firstSampleTime.timeIntervalSince1970)
                            NSLog("Written \(firstSampleTime) - \(lastSampleTime) samples.")
                            return (fileUrl, lastSampleTime)
                        } else {
                            encoder.close(0)
                            return nil
                        }
                    }
                }
            }
            
            return nil
        }
        
        ///
        /// We process the first session in our ``sessions`` map; if the sensor data is accessible
        /// we will transmit the data to the counterpart. If, as a result of processing this session,
        /// we remove it, we move on to the next session.
        ///
        func processFirstSession() {
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
            let from = props.accelerometerStart ?? session.start
            let to = props.end ?? NSDate()
            
            guard let (fileUrl, end) = encodeSamples(from: from, to: to, demo: session.demo) else {
                NSLog("No sensor data in \(from) - \(to)")
                return
            }
            
            // update the number of recorded samples
            let updatedProps = props.with(accelerometerEnd: end)
            sessions.update(session, newProps: updatedProps)
            
            // transfer what we have so far
            transferSensorDataBatch(fileUrl, session: session, props: updatedProps) {
                // set the expected range of samples on the next call
                let finalProps = updatedProps.with(accelerometerStart: end)
                self.sessions.update(session, newProps: finalProps)
                NSLog("Transferred \(finalProps)")
                
                // update the session with incremented sent counter
                if finalProps.completed {
                    NSLog("Removed \(finalProps)")
                    self.sessions.remove(session)
                    // we're done with this session, we can move on to the next one
                    processFirstSession()
                }
            }
        }
        
        // ask the SDR to record for another 12 hours just in case.
        recorder.recordAccelerometerForDuration(43200)
        
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
        // TODO: It would be nice to be able to flush the sensor data recorder
        // recorder.flush()
        dispatch_async(transferQueue, innerExecute)
    }

        
    ///
    /// Starts the exercise session with the given ``modelId`` and ``demo`` mode. In demo mode,
    /// the caller should explicitly call ``transferDemoSensorDataForCurrentSession``.
    ///
    /// - parameter modelId: the model id so that the phone can properly classify the data
    /// - parameter demo: set for demo mode
    ///
    public func startSession(modelId: MKExerciseModelId, demo: Bool) {
        let session = MKExerciseSession(id: NSUUID().UUIDString, start: NSDate(), demo: demo, modelId: modelId)
        sessions.add(session)
        WCSession.defaultSession().transferUserInfo(session.metadata)
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
    func plus(dict: [Key : Value]) -> [Key : Value] {
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
            "exerciseModelId" : modelId,
            "sessionId" : id,
            "start" : start.timeIntervalSince1970
        ]
    }
    
}

///
/// Adds the ``metadata`` property that can be used in P -> W comms
/// See ``MKExerciseConnectivitySession`` for the phone counterpart.
///
private extension MKExerciseSessionProperties {
    
    var metadata: [String : AnyObject] {
        var md: [String : AnyObject] = [
            "recorded" : recorded,
            "sent" : sent,
        ]
        if let end = end { md["end"] = end.timeIntervalSince1970 }
        if lastChunk { md["last"] = true }
        return md
    }
    
    /// Indicates if this chunk is the last of the session
    private var lastChunk: Bool {
        return ended && recorded >= MKConnectivitySettings.samplesForDuration(duration - 8.0) //(Int(duration - 8.0) * 50) // ok if miss last data window
    }
    
}

///
/// Allows the ``CMSensorDataList`` to be iterated over; unfortunately, the iteration
/// is not specifically-typed.
///
extension CMSensorDataList : SequenceType {
    
    public func generate() -> NSFastGenerator {
        return NSFastGenerator(self)
    }
}

#if (arch(i386) || arch(x86_64))
    
    class CMFakeAccelerometerData : CMAccelerometerData {
        override internal var acceleration: CMAcceleration {
            get {
                return CMAcceleration(x: 0, y: 0, z: 0)
            }
        }
    }
    
#endif
