import Foundation
import XCTest
import WatchConnectivity
@testable import MuvrKit

class MKConnectivityTests : XCTestCase {
    
    class WCMockSessionFile : WCSessionFile {
        private let _fileURL: NSURL
        private let _metadata: [String : AnyObject]?
        
        override var fileURL: NSURL {
            get {
                return _fileURL
            }
        }
        
        override var metadata: [String : AnyObject]? {
            get {
                return _metadata
            }
        }
        
        init(sensorData: MKSensorData, metadata: [String : AnyObject]) {
            let encoded = sensorData.encode()
            let cachesUrl = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.CachesDirectory, NSSearchPathDomainMask.UserDomainMask, true).first!
            let fileUrl = NSURL(fileURLWithPath: cachesUrl).URLByAppendingPathComponent("sensordata.raw")
            _ = try? NSFileManager.defaultManager().removeItemAtURL(fileUrl)
            encoded.writeToURL(fileUrl, atomically: true)
            
            self._fileURL = fileUrl
            self._metadata = metadata
        }
    }
    
    class Delegates : MKSensorDataConnectivityDelegate, MKExerciseConnectivitySessionDelegate {
        var accumulated: MKSensorData?
        var new: MKSensorData?
        var session: MKExerciseConnectivitySession?
        
        func sensorDataConnectivityDidReceiveSensorData(accumulated accumulated: MKSensorData, new: MKSensorData, session: MKExerciseConnectivitySession) {
            self.accumulated = accumulated
            self.new = new
        }
        
        func exerciseConnectivitySessionDidEnd(session session: MKExerciseConnectivitySession) {
            if self.session!.id == session.id { self.session = nil }
        }
        
        func exerciseConnectivitySessionDidStart(session session: MKExerciseConnectivitySession) {
            self.session = session
        }
    }
    
    func testStartEnd() {
        let delegates = Delegates()
        let c = MKConnectivity(sensorDataConnectivityDelegate: delegates, exerciseConnectivitySessionDelegate: delegates)
        let start = NSDate(timeIntervalSince1970: 1000)
        c.session(WCSession.defaultSession(), didReceiveUserInfo: ["action":"start", "sessionId":"1234", "exerciseModelId":"arms", "startDate":start.timeIntervalSince1970])
        XCTAssertEqual(delegates.session!.id, "1234")
        XCTAssertEqual(delegates.session!.exerciseModelId, "arms")
        XCTAssertEqual(delegates.session!.startDate, start)
        
        c.session(WCSession.defaultSession(), didReceiveUserInfo: ["action":"end", "sessionId":"1234"])
        XCTAssertTrue(delegates.session == nil)
    }

    func testSendSensorData() {
        let delegates = Delegates()
        let c = MKConnectivity(sensorDataConnectivityDelegate: delegates, exerciseConnectivitySessionDelegate: delegates)
        let start = NSDate()
        c.session(WCSession.defaultSession(), didReceiveUserInfo: ["action":"start", "sessionId":"1234", "exerciseModelId":"arms", "startDate":start.timeIntervalSince1970])
        
        let sensorData = try! MKSensorData(types: [.Accelerometer(location: .LeftWrist)], start: 0, samplesPerSecond: 50, samples: [Float](count: 300, repeatedValue: 0))
        let f = WCMockSessionFile(sensorData: sensorData, metadata: ["timestamp":NSTimeInterval(0)])
        c.session(WCSession.defaultSession(), didReceiveFile: f)
        c.session(WCSession.defaultSession(), didReceiveFile: f)
        
        XCTAssertEqual(delegates.new!, sensorData)
    }
    
}
