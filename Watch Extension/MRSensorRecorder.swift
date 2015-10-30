import Foundation
import CoreMotion
import MuvrKit

class MRSensorRecorder {

    ///
    /// Session metadata
    ///
    struct SessionMetadata: Hashable, Equatable {
        let id: String
        let start: NSDate
        let modelId: MKExerciseModelId
        
        var hashValue: Int {
            get {
                return id.hashValue
            }
        }
        
    }
    
    enum SessionTransferResult {
        case Transferred
        case NotTransferred
    }
    
    ///
    /// tracks the data sent and session end date
    ///
    typealias SessionTracker = (NSDate?, NSDate?)
    
    private let recorder: CMSensorRecorder = CMSensorRecorder()
    private var sessions: [SessionMetadata: SessionTracker] = [:]
    
    private let MAX_DURATION = 43200.0 // 12h
    
    func keepRecording() {
        recorder.recordAccelerometerForDuration(MAX_DURATION)
    }
    
    func newSession(id: String, start: NSDate, modelId: MKExerciseModelId) {
        let session = SessionMetadata(id: id, start: start, modelId: modelId)
        sessions[session] = (nil, nil)
    }
    
    func accelerometerDataForAllSessions(f: (SessionMetadata, Bool, MKSensorData) -> SessionTransferResult) -> Void {
        for (session, (lastSent, end)) in sessions {
            let toDate = end ?? NSDate()
            let from = lastSent ?? session.start
            let sensorData = recorder.accelerometerDataFromDate(from, toDate: toDate)
            
            // TODO: if sensorData contains all from .. end
            
            // the session has ended; we should have all the data for it
            let data = try! MKSensorData(types: [.Accelerometer(location: .LeftWrist)], start: 0, samplesPerSecond: 50, samples: [1,2,3])
            if f(session, true, data) == .Transferred {
                // OK to delete
                sessions[session] = nil
            }
        }
    }
    
}

func ==(lhs: MRSensorRecorder.SessionMetadata, rhs: MRSensorRecorder.SessionMetadata) -> Bool {
    return lhs.id == rhs.id
}

