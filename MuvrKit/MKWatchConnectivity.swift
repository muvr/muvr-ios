import Foundation
import CoreMotion
import WatchConnectivity

///
/// The Watch -> iOS connectivity; deals with the underlying mechanism of communication
/// and maintains
///
public class MKConnectivity : NSObject, WCSessionDelegate {
    public typealias OnFileTransferDone = SendDataResult -> Void
    
    private var onFileTransferDone: OnFileTransferDone?
    internal var transferringRealTime: Bool = false
    
    private let recorder: CMSensorRecorder = CMSensorRecorder()
    private var sessions: [MKExerciseSession: MKExerciseSessionProperties] = [:]

    ///
    /// Initializes this instance, assigninf the metadata ans sensorData delegates.
    /// This call should only happen once
    ///
    /// -parameter metadata: the metadata delegate
    /// -parameter sensorData: the sensor data delegate
    ///
    public init(delegate: MKMetadataConnectivityDelegate) {
        super.init()
        WCSession.defaultSession().delegate = self
        WCSession.defaultSession().activateSession()
        
        delegate.metadataConnectivityDidReceiveExerciseModelMetadata(defaultExerciseModelMetadata)
    }
    
    ///
    /// The response to data transmission
    ///
    public enum SendDataResult {
        ///
        /// The data was received by the receiver
        ///
        case Success
        
        case NoSession
        
        ///
        /// The sending operation failed
        ///
        /// - parameter error: the reason for the error
        ///
        case Error(error: NSError)
        
    }
    
    ///
    /// Returns the first encountered un-ended session
    ///
    public var currentSession: (MKExerciseSession, MKExerciseSessionProperties)? {
        for (session, props) in sessions where props.end == nil {
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
    /// Transfer ``sensorData`` immediately
    ///
    public func beginTransferSampleForLastSession(sensorData: MKSensorData) {
        if let (session, props) = sessions.first {
            self.sessions[session] = props.with(accelerometerStart: NSDate(), recorded: sensorData.rowCount)
            transferSensorDataBatch(sensorData, session: session, props: props) {
                switch $0 {
                case .Success: self.sessions[session] = props.with(sent: sensorData.rowCount)
                default: return
                }
            }
        }
    }
    
    ///
    /// Called when the file transfer completes.
    ///
    public func session(session: WCSession, didFinishFileTransfer fileTransfer: WCSessionFileTransfer, error: NSError?) {
        if let onDone = onFileTransferDone {
            if let e = error {
                onDone(.Error(error: e))
            } else {
                onDone(.Success)
            }
            
            onFileTransferDone = nil
        }
    }
    
    ///
    /// Ends the current session
    ///
    public func endLastSession() {
        for (session, props) in sessions where props.end == nil {
            sessions[session] = props.with(end: NSDate())
            break
        }
        beginTransfer()
    }
    
    public func beginTransfer() {
        func getSamples(from from: NSDate, to: NSDate) -> MKSensorData? {
            #if (arch(i386) || arch(x86_64))
                let duration = to.timeIntervalSinceDate(from)
                let samples = (0..<3 * 50 * Int(duration)).map { _ in return Float(0) }
                return try! MKSensorData(types: [.Accelerometer(location: .LeftWrist)], start: from.timeIntervalSince1970, samplesPerSecond: 50, samples: samples)
            #else
                // TODO: Check complete block
                return recorder.accelerometerDataFromDate(from, toDate: to).map { (recordedData: CMSensorDataList) -> MKSensorData in
                    let samples = recordedData.enumerate().flatMap { (_, e) -> [Float] in
                        if let data = e as? CMRecordedAccelerometerData {
                            return [Float(data.acceleration.x), Float(data.acceleration.y), Float(data.acceleration.z)]
                        }
                        return []
                    }
                    
                    return try! MKSensorData(types: [.Accelerometer(location: .LeftWrist)], start: from.timeIntervalSince1970, samplesPerSecond: 50, samples: samples)
                }
            #endif
        }

        recorder.recordAccelerometerForDuration(43200)

        NSLog("beginTransfer(); sessions = \(sessions)")
        
        if !WCSession.defaultSession().reachable {
            NSLog("Not reachable; not sending.")
            return
        }
        NSLog("Reachable; sending.")
        
        for (session, props) in sessions {
            let from = props.accelerometerStart ?? session.start
            let to = props.end ?? NSDate()
            if let sensorData = getSamples(from: from, to: to) {
                self.sessions[session] = props.with(accelerometerStart: from, recorded: sensorData.rowCount)
                transferSensorDataBatch(sensorData, session: session, props: props) {
                    switch $0 {
                    case .Success: self.sessions[session] = props.with(sent: sensorData.rowCount)
                    default: return
                    }
                }
            }
        }
        
        for (session, props) in sessions where props.end != nil {
            sessions.removeValueForKey(session)
        }
    }

        
    ///
    /// Starts the exercise session with the given 
    ///
    public func startSession(modelId: MKExerciseModelId, demo: Bool) {
        let session = MKExerciseSession(id: NSUUID().UUIDString, start: NSDate(), demo: demo, modelId: modelId)
        sessions[session] = MKExerciseSessionProperties(accelerometerStart: nil, end: nil, recorded: 0, sent: 0)
        WCSession.defaultSession().transferUserInfo(session.metadata)
    }

}

private extension Dictionary {
    
    func plus(dict: [Key : Value]) -> [Key : Value] {
        var result = self
        for (k, v) in dict {
            result.updateValue(v, forKey: k)
        }
        return result
    }
    
}

private extension MKExerciseSession {

    var metadata: [String : AnyObject] {
        return [
            "exerciseModelId" : modelId,
            "sessionId" : id,
            "start" : start.timeIntervalSince1970
        ]
    }
    
}

private extension MKExerciseSessionProperties {
    
    var metadata: [String : AnyObject] {
        var md: [String : AnyObject] = [
            "recorded" : recorded,
            "sent" : sent,
        ]
        if let end = end { md["end"] = end.timeIntervalSince1970 }
        if let accelerometerStart = accelerometerStart { md["accelerometerStart"] = accelerometerStart.timeIntervalSince1970 }
        
        return md
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
