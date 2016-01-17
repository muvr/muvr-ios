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
        let givenDetail: MKExerciseDetail = ("resistanceTargeted:arms/biceps-curl", MKExerciseType.ResistanceWholeBody, [])
        let givenLabels: [MKExerciseLabel] = [.Repetitions(repetitions: 10), .Intensity(intensity: 0.5), .Weight(weight: 40)]

        try! app.startSessionForExerciseType(.ResistanceTargeted(muscleGroups: [.Arms, .Chest]), start: NSDate(), id: NSUUID().UUIDString)
        app.currentSession!.addExerciseDetail(givenDetail, labels: givenLabels, start: NSDate(), duration: 10)
        try! app.endCurrentSession()
        
        try! app.startSessionForExerciseType(.ResistanceTargeted(muscleGroups: [.Arms, .Chest]), start: NSDate(), id: NSUUID().UUIDString)
        let bc = app.currentSession!.exerciseDetailsComingUp.first!
        XCTAssertEqual(bc.0, givenDetail.0)
        let labels = app.currentSession!.predictExerciseLabelsForExerciseDetail(bc)
        XCTAssertEqual(givenLabels, labels)
        try! app.endCurrentSession()
    }
    
}

