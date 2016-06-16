import Foundation
import XCTest
import MuvrKit
import CoreLocation
import CoreData
@testable import Muvr

class MRAppTests : XCTestCase {
    
    var app: MRAppDelegate {
        return UIApplication.sharedApplication().delegate as! MRAppDelegate
    }
    
    
    func testStartEndWithNoLocation() {
        try! app.startSession(.AdHoc(exerciseType: .ResistanceTargeted(muscleGroups: [.Arms, .Chest])))
        try! app.endCurrentSession()
    }
    
    func testStartEndJansLair() {
        app.locationManager(CLLocationManager(), didUpdateLocations: [CLLocation(latitude: 53.425416, longitude: -2.225455)])
        let givenDetail: MKExerciseDetail = MKExerciseDetail(id: "resistanceTargeted:arms/dumbbell-biceps-curl", type: MKExerciseType.ResistanceWholeBody, muscle: .Biceps, labels: [.Repetitions, .Weight, .Intensity], properties: [])
        let givenLabels: [MKExerciseLabel] = [.Repetitions(repetitions: 10), .Intensity(intensity: 0.6), .Weight(weight: 40)]

        // start a new session, adding one exercise
        let sessionId = try! app.startSession(.AdHoc(exerciseType: .ResistanceTargeted(muscleGroups: [.Arms, .Chest])))
        app.currentSession!.addExerciseDetail(givenDetail, labels: givenLabels, start: Date(), duration: 10)
        let (predicted1, _) = app.currentSession!.predictExerciseLabelsForExerciseDetail(givenDetail)
        XCTAssertEqual(givenLabels.filter { $0.descriptor != .Intensity }.sort { $0.0.id < $0.1.id }, predicted1.0.sort { $0.0.id < $0.1.id })
        try! app.endCurrentSession()
        
        // try to load it
        let f = NSFetchRequest(entityName: "MRManagedExerciseSession")
        f.predicate = Predicate(format: "id=%@", sessionId)
        let r = try! app.managedObjectContext.executeFetchRequest(f).first! as! MRManagedExerciseSession
        let e = (r.exercises.allObjects as! [MRManagedExercise]).first!
        let l = e.scalarLabels.allObjects as! [MRManagedExerciseScalarLabel]
        XCTAssertEqual(l.count, givenLabels.count)

        // start a different session but with the same exercise type
        try! app.startSession(.AdHoc(exerciseType: .ResistanceTargeted(muscleGroups: [.Arms, .Chest])))
        // expect the right preciction
        let bc = app.currentSession!.exerciseDetailsComingUp.first!
        XCTAssertEqual(bc.id, givenDetail.id)
        let (predicted2, _) = app.currentSession!.predictExerciseLabelsForExerciseDetail(bc)
        XCTAssertEqual(givenLabels.filter { $0.descriptor != .Intensity }.sort { $0.0.id < $0.1.id }, predicted2.0.sort { $0.0.id < $0.1.id })
        try! app.endCurrentSession()
        
    }
    
}

