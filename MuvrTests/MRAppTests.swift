import Foundation
import XCTest
import MuvrKit
import CoreLocation
@testable import Muvr

class MRAppTests : XCTestCase {
    let app: MRAppDelegate = {
        let d = MRAppDelegate()
        d.application(UIApplication.sharedApplication(), didFinishLaunchingWithOptions: nil)
        return d
    }()
    
    func testStartEndWithNoLocation() {
        try! app.startSessionForExerciseType(.ResistanceTargeted(muscleGroups: [.Arms, .Chest]), start: NSDate(), id: NSUUID().UUIDString)
        try! app.endCurrentSession()
    }
    
    func testStartEndJansLair() {
        app.locationManager(CLLocationManager(), didUpdateLocations: [CLLocation(latitude: 53.425416, longitude: -2.225455)])

        try! app.startSessionForExerciseType(.ResistanceTargeted(muscleGroups: [.Arms, .Chest]), start: NSDate(), id: NSUUID().UUIDString)
        try! app.endCurrentSession()
    }
    
}

