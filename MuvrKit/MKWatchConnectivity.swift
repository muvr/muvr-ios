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
    public func transferSensorDataBatch(data: MKSensorData, session: MKExerciseSession, onDone: OnFileTransferDone) {
        if onFileTransferDone == nil {
            onFileTransferDone = onDone
            let encoded = data.encode()
            let documentsUrl = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true).first!
            let fileUrl = NSURL(fileURLWithPath: documentsUrl).URLByAppendingPathComponent("sensordata.raw")
            
            if encoded.writeToURL(fileUrl, atomically: true) {
                WCSession.defaultSession().transferFile(fileUrl, metadata: session.metadata(["timestamp": NSDate().timeIntervalSince1970]))
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
        
        for (session, props) in sessions {
            let from = props.accelerometerStart ?? session.start
            let to = props.end ?? NSDate()
            if let sensorData = getSamples(from: from, to: to) {
                transferSensorDataBatch(sensorData, session: session) {
                    switch $0 {
                    case .Success: self.sessions[session] = props.with(accelerometerStart: from).with(recordedDelta: sensorData.rowCount, sentDelta: sensorData.rowCount)
                    default: return
                    }
                }
            }
        }
        
        for (session, props) in sessions where props.end != nil {
            let message = session.metadata(["action": "end"])
            WCSession.defaultSession().transferUserInfo(message)
            sessions[session] = nil
        }
    }

        
    ///
    /// Starts the exercise session with the given 
    ///
    public func startSession(modelId: MKExerciseModelId, demo: Bool) {
        let session = MKExerciseSession(id: NSUUID().UUIDString, start: NSDate(), demo: demo, modelId: modelId)
        sessions[session] = MKExerciseSessionProperties(accelerometerStart: nil, end: nil, recorded: 0, sent: 0)
        let message = session.metadata(["action": "start"])
        WCSession.defaultSession().transferUserInfo(message)
    }

}

private extension MKExerciseSession {

    func metadata(extra: [String : AnyObject] = [:]) -> [String : AnyObject] {
        var metadata: [String : AnyObject] = [
            "exerciseModelId" : modelId,
            "sessionId" : id,
            "startDate" : start.timeIntervalSince1970
        ]
        for (k, v) in extra {
            metadata[k] = v
        }
        
        return metadata
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
