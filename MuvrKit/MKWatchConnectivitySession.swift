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
final public class MKExerciseSession : NSObject {
    private unowned let connectivity: MKConnectivity
    
    let id: String
    private var sensorRecorder: CMSensorRecorder?
    
    #if WITH_RT
    
    private var motionManager: CMMotionManager?
    #if (arch(i386) || arch(x86_64))
    private var timer: NSTimer?
    #endif
    private var lastAccelerometerUpdateTime: NSDate?
    private var realTimeSamples: [Float] = []
    private let accelerometerQueue: NSOperationQueue

    #endif
    
    private let startTime: NSDate
    private var lastSentStartTime: NSDate
    private let exerciseModelMetadata: MKExerciseModelMetadata
    
    private var stats: MKExerciseSessionStats
    
    
    init(connectivity: MKConnectivity, exerciseModelMetadata: MKExerciseModelMetadata) {
        self.connectivity = connectivity
        self.exerciseModelMetadata = exerciseModelMetadata
        self.startTime = NSDate()
        self.lastSentStartTime = startTime
        self.sensorRecorder = CMSensorRecorder()
        self.id = NSUUID().UUIDString
        self.stats = MKExerciseSessionStats()
        #if WITH_RT
        self.accelerometerQueue = NSOperationQueue()
        self.accelerometerQueue.qualityOfService = NSQualityOfService.UserInitiated
        #endif
        
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
    
    #if WITH_RT
    ///
    /// Indicates whether this session is sending data in real-time
    ///
    public var isRealTime: Bool {
        return motionManager != nil
    }
    
    public func beginSendRealTime(onDone: () -> Void) {
        if motionManager != nil {
            motionManager!.stopAccelerometerUpdates()
        }

        self.lastAccelerometerUpdateTime = nil
        self.stats.realTimeCounter = MKExerciseSessionStats.SampleCounter()
        self.realTimeSamples = []
        
        

        #if (arch(i386) || arch(x86_64))
            self.timer = NSTimer.scheduledTimerWithTimeInterval(1.0 / 50.0, target: self, selector: "fakeAccelerometerHandler", userInfo: nil, repeats: true)
        #endif
        connectivity.beginRealTime() {
            self.motionManager = CMMotionManager()
            self.motionManager!.accelerometerUpdateInterval = 1.0 / 50.0
            self.motionManager!.startAccelerometerUpdatesToQueue(self.accelerometerQueue, withHandler: self.accelerometerHandler)
            
            onDone()
        }
    }
    
    public func endSendRealTime(onDone: (() -> Void)?) {
        if let motionManager = motionManager {
            
            #if (arch(i386) || arch(x86_64))
                timer?.invalidate()
                timer = nil
            #endif
            
            motionManager.stopAccelerometerUpdates()
            if realTimeSamples.count > 0 {
                let samples = try! MKSensorData(types: [.Accelerometer(location: .LeftWrist)], start: 0, samplesPerSecond: 50, samples: realTimeSamples)
                connectivity.transferSensorDataRealTime(samples, onDone: nil)
            }
        }
        connectivity.endRealTime() {
            self.stats.realTimeCounter = nil
            self.realTimeSamples = []
            if let f = onDone { f() }
        }
        self.motionManager = nil
    }
    
    #if (arch(i386) || arch(x86_64))
    public func fakeAccelerometerHandler() {
        accelerometerHandler(CMFakeAccelerometerData(), error: nil)
    }
    #endif

    private func accelerometerHandler(data: CMAccelerometerData?, error: NSError?) {
        let now = NSDate()
        if let lat = lastAccelerometerUpdateTime {
            let interval = now.timeIntervalSinceDate(lat)
            
            if interval > 1 {
                // the thread got suspended while running ~> we end RT updates
                self.endSendRealTime(nil)
                return
            }
        }
        lastAccelerometerUpdateTime = now
        
        // accumulate data
        if let data = data {
            realTimeSamples.append(Float(data.acceleration.x))
            realTimeSamples.append(Float(data.acceleration.y))
            realTimeSamples.append(Float(data.acceleration.z))
        }
        
        stats.realTimeCounter?.recorded += 1

        // we send 100 samples at a time
        if realTimeSamples.count >= 300 && !connectivity.transferringRealTime {
            let samples = try! MKSensorData(types: [.Accelerometer(location: .LeftWrist)], start: 0, samplesPerSecond: 50, samples: realTimeSamples)
            connectivity.transferSensorDataRealTime(samples) {
                self.realTimeSamples = []
                self.stats.realTimeCounter?.sent += self.realTimeSamples.count / 3
            }
        }
    }
    #endif
    
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
    /// Session model metadata
    ///
    public var title: String {
        return self.exerciseModelMetadata.1
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

#if (arch(i386) || arch(x86_64))

    class CMFakeAccelerometerData : CMAccelerometerData {
        override internal var acceleration: CMAcceleration {
            get {
                return CMAcceleration(x: 0, y: 0, z: 0)
            }
        }
    }
    
#endif
