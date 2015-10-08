import Foundation
import CoreMotion
import WatchConnectivity

public class MKExerciseSession {
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
        //        self.sensorRecorder = nil
    }
    
    ///
    /// The session title
    ///
    public var exerciseModelTitle: String {
        return exerciseModelMetadata.1
    }
    
    ///
    /// Send the data collected so far to the Phone
    ///
    public func sendImmediately() {
        let now = NSDate()
        // 24 kiB OK
        let samples = (0..<300000).map { Float($0) }
        var sd = try! MKSensorData(types: [.Accelerometer(location: .LeftWrist)], start: lastSentStartTime.timeIntervalSinceNow, samplesPerSecond: 100, samples: samples)
        if let recordedData = sensorRecorder!.accelerometerDataFromDate(lastSentStartTime, toDate: now) {
            for (_, data) in recordedData.enumerate() {
                
            }
        }
        
        connectivity.transferSensorData(sd) {
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
    
    ///
    /// Gets the session length
    ///
    public func getSessionLength() -> NSTimeInterval {
        return NSDate().timeIntervalSinceDate(self.startTime)
    }
    
}

extension CMSensorDataList: SequenceType {
    public func generate() -> NSFastGenerator {
        return NSFastGenerator(self)
    }
}