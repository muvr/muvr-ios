import Foundation
import CoreMotion
import HealthKit
import MuvrKit

class MRExerciseSession {
    private var sensorRecorder: CMSensorRecorder?
    private let startTime: NSDate
    private var recordedSensorStart: NSDate
    private let exerciseModelMetadata: MKExerciseModelMetadata
    private unowned let connectivity: MKConnectivity
    private var sampleCount: Int
    
    init(connectivity: MKConnectivity, exerciseModelMetadata: MKExerciseModelMetadata) {
        self.connectivity = connectivity
        self.exerciseModelMetadata = exerciseModelMetadata
        self.startTime = NSDate()
        self.recordedSensorStart = startTime
        self.sampleCount = 0
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
    /// The sample count
    ///
    func getSampleCount() -> Int {
        let now = NSDate()
        if let c = (sensorRecorder!.accelerometerDataFromDate(recordedSensorStart, toDate: now).map { $0.enumerate().reduce(0) { r, x in return r + 1 } }) {
            sampleCount += c
        }
        recordedSensorStart = now
        
        return sampleCount
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