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
    private var motionManager: CMMotionManager?
    
    private let startTime: NSDate
    private var lastSentStartTime: NSDate
    private let exerciseModelMetadata: MKExerciseModelMetadata
    
    private var stats: MKExerciseSessionStats
    
    private var lastAccelerometerUpdateTime: NSDate?
    private var realTimeStartTime: NSDate?
    private var realTimeSamples: [Float] = []
    
    init(connectivity: MKConnectivity, exerciseModelMetadata: MKExerciseModelMetadata) {
        self.connectivity = connectivity
        self.exerciseModelMetadata = exerciseModelMetadata
        self.startTime = NSDate()
        self.lastSentStartTime = startTime
        self.sensorRecorder = CMSensorRecorder()
        self.id = NSUUID().UUIDString
        self.stats = MKExerciseSessionStats()
        
        // TODO: Sort out recording duration
        self.sensorRecorder!.recordAccelerometerForDuration(NSTimeInterval(3600 * 2))
    }
    
    deinit {
        self.sensorRecorder = nil
    }
    
    ///
    /// Indicates whether this session is sending data in real-time
    ///
    public var isRealTime: Bool {
        return motionManager != nil
    }
    
    ///
    /// The session title
    ///
    public var exerciseModelTitle: String {
        return exerciseModelMetadata.1
    }
    
    public func beginSendRealTime(onDone: () -> Void) {
        if motionManager == nil {
            connectivity.beginRealTime() {
                self.motionManager = CMMotionManager()
                self.motionManager!.accelerometerUpdateInterval = 1.0 / 50.0
                self.motionManager!.startAccelerometerUpdatesToQueue(NSOperationQueue.mainQueue(), withHandler: self.accelerometerHandler)
                self.stats.realTimeCounter = MKExerciseSessionStats.SampleCounter()
                self.realTimeSamples = []
                self.realTimeStartTime = NSDate()
                onDone()
            }
        }
    }
    
    public func endSendRealTime(onDone: (() -> Void)?) {
        if let motionManager = motionManager, realTimeStartTime = realTimeStartTime {
            motionManager.stopAccelerometerUpdates()
            if realTimeSamples.count > 0 {
                let samples = try! MKSensorData(types: [.Accelerometer(location: .LeftWrist)], start: realTimeStartTime.timeIntervalSince1970, samplesPerSecond: 50, samples: realTimeSamples)
                connectivity.transferSensorDataRealTime(samples, onDone: nil)
            }
        }
        connectivity.endRealTime() {
            self.motionManager = nil
            self.stats.realTimeCounter = nil
            self.realTimeStartTime = nil
            self.realTimeSamples = []
            if let f = onDone { f() }
        }
    }
    
    private func accelerometerHandler(data: CMAccelerometerData?, error: NSError?) {
        let now = NSDate()
        if let lastAccelerometerUpdateTime = lastAccelerometerUpdateTime {
            let interval = now.timeIntervalSinceDate(lastAccelerometerUpdateTime)
            
            if interval > 1 {
                // the thread got suspended while running ~> we end RT updates
                self.endSendRealTime(nil)
                return
            }
        }
        lastAccelerometerUpdateTime = now
        
        if let data = data {
            realTimeSamples.append(Float(data.acceleration.x))
            realTimeSamples.append(Float(data.acceleration.y))
            realTimeSamples.append(Float(data.acceleration.z))
        }
        
        // we send 100 samples at a time
        if let realTimeStartTime = realTimeStartTime {
            if realTimeSamples.count > 300 {
                let samples = try! MKSensorData(types: [.Accelerometer(location: .LeftWrist)], start: realTimeStartTime.timeIntervalSince1970, samplesPerSecond: 50, samples: realTimeSamples)
                connectivity.transferSensorDataRealTime(samples) {
                    self.realTimeSamples = []
                    self.realTimeStartTime = NSDate()
                }
            }
        }
    }
    
    ///
    /// Send the data collected so far to the mobile counterpart
    ///
    public func beginSendBatch() {
        
        func getSamples(toDate: NSDate) -> MKSensorData? {
            return sensorRecorder!.accelerometerDataFromDate(lastSentStartTime, toDate: toDate).map { (recordedData: CMSensorDataList) -> MKSensorData in
                let samples = recordedData.enumerate().flatMap { (_, e) -> [Float] in
                    if let data = e as? CMRecordedAccelerometerData {
                        return [Float(data.acceleration.x), Float(data.acceleration.y), Float(data.acceleration.z)]
                    }
                    return []
                }
                
                return try! MKSensorData(types: [.Accelerometer(location: .LeftWrist)], start: lastSentStartTime.timeIntervalSince1970, samplesPerSecond: 50, samples: samples)
            }
        }
        
        /*
        WCSession.sendData is OK for ~24 kiB blocks
        anything bigger needs something more efficient
        here, we use the recorded acceleration data
        */
        
        let now = NSDate()
        if let samples = getSamples(now) {
            stats.batchCounter.recorded += samples.rowCount
            connectivity.transferSensorDataBatch(samples) {
                switch $0 {
                case .Error(error: _):
                    return
                case .NoSession:
                    return
                case .Success:
                    self.stats.batchCounter.sent += samples.rowCount
                    self.lastSentStartTime = now
                }
            }
            
        }
    }
    
    ///
    /// The session stats
    ///
    public var sessionStats: MKExerciseSessionStats {
        return stats
    }
    
    ///
    /// Gets the session duration
    ///
    public var sessionDuration: NSTimeInterval {
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