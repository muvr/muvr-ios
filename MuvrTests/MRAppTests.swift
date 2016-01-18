import Foundation
import XCTest
import MuvrKit
import CoreLocation
import CoreData
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

        // start a new session, adding one exercise
        let sessionId = NSUUID().UUIDString
        try! app.startSessionForExerciseType(.ResistanceTargeted(muscleGroups: [.Arms, .Chest]), start: NSDate(), id: sessionId)
        app.currentSession!.addExerciseDetail(givenDetail, labels: givenLabels, start: NSDate(), duration: 10)
        let l1 = app.currentSession!.predictExerciseLabelsForExerciseDetail(givenDetail)
        XCTAssertEqual(givenLabels.sort { $0.0.id < $0.1.id }, l1.sort { $0.0.id < $0.1.id })
        try! app.endCurrentSession()
        
        // try to load it
        let f = NSFetchRequest(entityName: "MRManagedExerciseSession")
        f.predicate = NSPredicate(format: "id=%@", sessionId)
        let r = try! app.managedObjectContext.executeFetchRequest(f).first! as! MRManagedExerciseSession
        let e = (r.exercises.allObjects as! [MRManagedExercise]).first!
        let l = e.scalarLabels.allObjects as! [MRManagedExerciseScalarLabel]
        XCTAssertEqual(l.count, givenLabels.count)

        // start a different session but with the same exercise type
        try! app.startSessionForExerciseType(.ResistanceTargeted(muscleGroups: [.Arms, .Chest]), start: NSDate(), id: NSUUID().UUIDString)
        // expect the right preciction
        let bc = app.currentSession!.exerciseDetailsComingUp.first!
        XCTAssertEqual(bc.0, givenDetail.0)
        let labels = app.currentSession!.predictExerciseLabelsForExerciseDetail(bc)
        XCTAssertEqual(givenLabels.sort { $0.0.id < $0.1.id }, labels.sort { $0.0.id < $0.1.id })
        try! app.endCurrentSession()
        
    }
    
}

