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
    private(set) public var sessions: [MKExerciseSession: MKExerciseSessionProperties] = [:]
    private let transferQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)

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
    
    ///
    /// Returns the first encountered un-ended session
    ///
    public var currentSession: (MKExerciseSession, MKExerciseSessionProperties)? {
        if let (session, props) = mostImportantSessionsEntry() where !props.ended {
            return (session, props)
        }
        return nil
    }
    
    ///
    /// Sends the sensor data ``data`` invoking ``onDone`` when the operation completes. The callee should
    /// check the value of ``SendDataResult`` to see if it should retry the transimssion, or if it can safely
    /// trim the data it has collected so far.
    ///
    /// - parameter data: the sensor data to be sent
    /// - parameter onDone: the function to be executed on completion (success or error)
    ///
    func transferSensorDataBatch(data: MKSensorData, session: MKExerciseSession, props: MKExerciseSessionProperties?, onDone: OnFileTransferDone) {
        if onFileTransferDone == nil {
            onFileTransferDone = onDone
            let encoded = data.encode()
            let documentsUrl = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true).first!
            let fileUrl = NSURL(fileURLWithPath: documentsUrl).URLByAppendingPathComponent("sensordata.raw")
            
            if encoded.writeToURL(fileUrl, atomically: true) {
                var metadata = session.metadata
                if let props = props { metadata = metadata.plus(props.metadata) }
                metadata["timestamp"] = NSDate().timeIntervalSince1970
                WCSession.defaultSession().transferFile(fileUrl, metadata: metadata)
            }
        }
    }
    
    ///
    /// Transfer sensor data if there is a not-yet-ended demo session
    ///
    /// - parameter sensorData: the sensor data to be transferred
    ///
    public func transferDemoSensorDataForCurrentSession(sensorData: MKSensorData) {
        for (session, props) in sessions where !props.ended && session.demo {
            self.sessions[session] = props.with(accelerometerEnd: NSDate())
            transferSensorDataBatch(sensorData, session: session, props: props) {
                self.sessions[session] = props.with(accelerometerStart: NSDate())
            }
            NSLog("Transferred.")
            return
        }
    }
    
    ///
    /// Called when the file transfer completes.
    ///
    public func session(session: WCSession, didFinishFileTransfer fileTransfer: WCSessionFileTransfer, error: NSError?) {
        if let onDone = onFileTransferDone {
            onDone()
            onFileTransferDone = nil
        }
    }
    
    ///
    /// Ends the current session
    ///
    public func endLastSession() {
        if let (session, props) = currentSession where !props.ended {
            objc_sync_enter(self)
            defer { objc_sync_exit(self) }
            
            let endedProps = props.with(end: NSDate())
            sessions[session] = endedProps
            // notify phone that this session is over
            WCSession.defaultSession().transferUserInfo(session.metadata.plus(endedProps.metadata))
        } else {
            NSLog("No session to end")
        }
        // still try to send remaining data
        execute()
    }
    
    ///
    /// Returns the most important session for processing, if available
    ///
    private func mostImportantSessionsEntry() -> (MKExerciseSession, MKExerciseSessionProperties)? {
        // pick the not-yet-ended session first
        for (session, props) in sessions {
            if props.end == nil {
                return (session, props)
            }
        }
        
        // then whichever one remains
        return sessions.first
    }
    
    ///
    /// Implements the protocol for the W -> P communication by collecting the data from the sensor recorder,
    /// constructing the messages and dealing with session clean-up.
    ///
    public func execute() {
        func getSamples(from from: NSDate, to: NSDate, demo: Bool) -> MKSensorData? {
            var simulatedSamples = demo
            
            #if (arch(i386) || arch(x86_64))
                simulatedSamples = true
            #endif
            
            let duration = to.timeIntervalSinceDate(from)
            let sampleCount = dimension * MKConnectivitySettings.samplingRate * Int(duration)
            
            // Indicates if the expected sample is in the requested range
            func isInRange(sample: CMRecordedAccelerometerData) -> Bool {
                // check only 'start' time - don't care about end of range
                return from.timeIntervalSince1970 <= sample.startDate.timeIntervalSince1970
            }
            
            // Indicates if the sample is the expected one (regarding recorded time)
            // It allows to check for ``missing`` samples in the requested range
            func isExpectedSample(sample: CMRecordedAccelerometerData, lastTime: NSDate?) -> Bool {
                if let lastTime = lastTime {
                    // check sample is not more than 40ms apart from last one
                    return sample.startDate.timeIntervalSinceDate(lastTime) < 0.04
                } else {
                    // first sample: check it is in range
                    return isInRange(sample)
                }
            }
            
            if simulatedSamples {
                let samples = (0..<sampleCount).map { _ in return Float(0) }
                return try! MKSensorData(types: recordedTypes, start: from.timeIntervalSince1970, samplesPerSecond: 50, samples: samples)
            } else {
                var sampleStart: NSDate? = nil
                var lastTime: NSDate? = nil
                return recorder.accelerometerDataFromDate(from, toDate: to).flatMap { (recordedData: CMSensorDataList) -> MKSensorData? in
                    let samples = recordedData.enumerate().flatMap { (_, e) -> [Float] in
                        if let data = e as? CMRecordedAccelerometerData where isExpectedSample(data, lastTime: lastTime) {
                            if sampleStart == nil { // first sample - set range start date
                                sampleStart = data.startDate
                            }
                            lastTime = data.startDate
                            return [Float(data.acceleration.x), Float(data.acceleration.y), Float(data.acceleration.z)]
                        }
                        return []
                    }
                    return try! MKSensorData(types: recordedTypes, start: sampleStart!.timeIntervalSince1970, samplesPerSecond: 50, samples: samples)
                }
            }
        }
        
        ///
        /// We process the first session in our ``sessions`` map; if the sensor data is accessible
        /// we will transmit the data to the counterpart. If, as a result of processing this session,
        /// we remove it, we move on to the next session.
        ///
        func processFirstSession() {
            objc_sync_enter(self)
            
            defer { objc_sync_exit(self) }
            
            // pick the most important entry
            guard let (session, props) = mostImportantSessionsEntry() else {
                NSLog("No session")
                return
            }
            
            // compute the dates
            let from = props.accelerometerStart ?? session.start
            let to = props.end ?? NSDate()
            
            guard let sensorData = getSamples(from: from, to: to, demo: session.demo) else {
                NSLog("No sensor data in \(from) - \(to)")
                return
            }

            // update the number of recorded samples
            let readFromDate = NSDate(timeIntervalSince1970: sensorData.end)
            let updatedProps = props.with(accelerometerEnd: readFromDate)
            self.sessions[session] = updatedProps
            
            // transfer what we have so far
            transferSensorDataBatch(sensorData, session: session, props: updatedProps) {
                // REVIEW: does this fix the sessions problem?
                if self.sessions[session] == nil {
                    NSLog("Session \(session) already removed.")
                    dispatch_async(self.transferQueue, processFirstSession)
                } else {
                    // set the expected range of samples on the next call
                    let finalProps = updatedProps.with(accelerometerStart: readFromDate)
                    self.sessions[session] = finalProps

                    // update the session with incremented sent counter
                    if finalProps.completed {
                        NSLog("Remove completed session \(session)")
                        self.sessions.removeValueForKey(session)
                        // we're done with this session, we can move on to the next one
                        dispatch_async(self.transferQueue, processFirstSession)
                    }
                    
                    NSLog("Transferred \(sensorData.rowCount) samples; with \(self.sessions.count) active sessions.")
                }
            }
        }
        
        // ask the SDR to record for another 12 hours just in case.
        recorder.recordAccelerometerForDuration(43200)

        // check whether there is something to be done at all.
        NSLog("beginTransfer(); sessions = \(sessions)")
        if sessions.count == 0 {
            NSLog("Reachable; no active sessions.")
            return
        }
        
        // it makes sense to continue the work.
        NSLog("Reachable; with \(sessions.count) active sessions.")
        
        // TODO: It would be nice to be able to flush the sensor data recorder
        // recorder.flush()
        dispatch_async(transferQueue, processFirstSession)
        
        NSLog("Done; with \(sessions.count) active sessions.")
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
        sessions[session] = MKExerciseSessionProperties(start: session.start)
        WCSession.defaultSession().transferUserInfo(session.metadata)
    }
    
    /// The debug description
    public override var description: String {
        if let (s, p) = mostImportantSessionsEntry() {
            return "\(sessions.count): \(s.id.characters.first!): \(p.sent)/\(Int(p.duration) * 50)"
        }
        return "0"
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
