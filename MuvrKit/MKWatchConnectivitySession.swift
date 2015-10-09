import Foundation
import CoreMotion
import WatchConnectivity

///
/// Implements the exercise session in the Watch, all the way down to scheduling sensor data delivery.
/// You cannot create instances of this class explicitly, you must use the appropriate functions in
/// the ``MKConnectivity``.
///
/// During the lifetime of the session, the watch application should call ``sendImmediately`` whenever
/// it is awake. This delivers the recorded sensor data to the mobile counterpart, which will classify
/// the incoming data as soon as possible, delivering results back to the watch app.
///
/// If you do not get a chance to explicitly call ``sendImmediately``, it will be called on ``deinit``.
/// In this scenario, the watch app is closing, and so the watch app will send the *entire* recorded
/// block to the mobile counterpart, and will not get the opportunity to process the results until
/// it starts the next time.
///
final public class MKExerciseSession {
    private unowned let connectivity: MKConnectivity
    
    let id: String
    private var sensorRecorder: CMSensorRecorder?
    private let startTime: NSDate
    private var lastSentStartTime: NSDate
    private let exerciseModelMetadata: MKExerciseModelMetadata
    
    init(connectivity: MKConnectivity, exerciseModelMetadata: MKExerciseModelMetadata) {
        self.connectivity = connectivity
        self.exerciseModelMetadata = exerciseModelMetadata
        self.startTime = NSDate()
        self.lastSentStartTime = startTime
        self.sensorRecorder = CMSensorRecorder()
        self.id = NSUUID().UUIDString
        
        // TODO: Sort out recording duration
        self.sensorRecorder!.recordAccelerometerForDuration(NSTimeInterval(3600 * 2))
    }
    
    deinit {
        self.sensorRecorder = nil
    }
    
    ///
    /// The session title
    ///
    public var exerciseModelTitle: String {
        return exerciseModelMetadata.1
    }
    
    ///
    /// Send the data collected so far to the mobile counterpart
    ///
    public func sendImmediately() {
        
    #if __arm__ || __thumb__
        func getSamples(toDate: NSDate) -> MKSensorData? {
            return sensorRecorder!.accelerometerDataFromDate(lastSentStartTime, toDate: toDate).map { (recordedData: CMSensorDataList) -> MKSensorData in
                let samples = recordedData.enumerate().flatMap { (_, e) -> [Float] in
                    if let data = e as? CMRecordedAccelerometerData {
                        return [Float(data.acceleration.x), Float(data.acceleration.y), Float(data.acceleration.z)]
                    }
                    return []
                }
                
                return try! MKSensorData(types: [.Accelerometer(location: .LeftWrist)], start: lastSentStartTime.timeIntervalSinceNow, samplesPerSecond: 100, samples: samples)
            }
        }
    #else
        func getSamples(toDate: NSDate) -> MKSensorData? {
            // assume 100 samples per second
            let sampleCount = Int(toDate.timeIntervalSinceDate(lastSentStartTime) * 100)
            let samples = (0..<sampleCount * 3).map { _ in return Float(0) }
            return try! MKSensorData(types: [.Accelerometer(location: .LeftWrist)], start: lastSentStartTime.timeIntervalSinceNow, samplesPerSecond: 100, samples: samples)
        }
    #endif
        
        /*
        WCSession.sendData is OK for ~24 kiB blocks
        anything bigger needs something more efficient
        here, we use the recorded acceleration data
        */
        
        let now = NSDate()
        if let samples = getSamples(now) {
            connectivity.transferSensorData(samples) {
                switch $0 {
                case .Error(error: _):
                    return
                case .NoSession:
                    return
                case .Success:
                    self.lastSentStartTime = now
                }
            }
            
        }
    }
    
    ///
    /// Gets the session length
    ///
    public func getSessionLength() -> NSTimeInterval {
        return NSDate().timeIntervalSinceDate(self.startTime)
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