import Foundation
import CoreMotion
import HealthKit
import MuvrKit

class MRExerciseSession {
    private unowned let connectivity: MKConnectivity

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
        
        // TODO: Sort out recording duration
        self.sensorRecorder!.recordAccelerometerForDuration(NSTimeInterval(3600 * 2))
    }
    
    deinit {
//        self.sensorRecorder = nil
    }
    
    ///
    /// The session title
    ///
    var exerciseModelTitle: String {
        return exerciseModelMetadata.1
    }
    
    ///
    /// Send the data collected so far to the Phone
    ///
    func sendImmediately() {
        let now = NSDate()
        var sd = try! MKSensorData(types: [.Accelerometer(location: .LeftWrist)], start: lastSentStartTime.timeIntervalSinceNow, samplesPerSecond: 100, samples: [])
        if let recordedData = sensorRecorder!.accelerometerDataFromDate(lastSentStartTime, toDate: now) {
            for (_, data) in recordedData.enumerate() {
                
            }
        }
        
        connectivity.beginTransferSensorData(sd) {
            switch $0 {
            case .Error(error: _): return
            case .Success: self.lastSentStartTime = now
            }
        }
    }

    ///
    /// Gets the session length
    ///
    func getSessionLength() -> NSTimeInterval {
        return NSDate().timeIntervalSinceDate(self.startTime)
    }
    
}

extension CMSensorDataList: SequenceType {
    public func generate() -> NSFastGenerator {
        return NSFastGenerator(self)
    }
}