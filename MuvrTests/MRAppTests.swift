import Foundation
import XCTest
import MuvrKit
import CoreLocation
import CoreData
@testable import Muvr

class MRAppTests : XCTestCase {
    
    var app: MRAppDelegate {
        return UIApplication.shared().delegate as! MRAppDelegate
    }
    
    
    func testStartEndWithNoLocation() {
        try! app.startSession(.adHoc(exerciseType: .resistanceTargeted(muscleGroups: [.arms, .chest])))
        try! app.endCurrentSession()
    }
    
    func testStartEndJansLair() {
        app.locationManager(CLLocationManager(), didUpdateLocations: [CLLocation(latitude: 53.425416, longitude: -2.225455)])
        let givenDetail: MKExerciseDetail = MKExerciseDetail(id: "resistanceTargeted:arms/dumbbell-biceps-curl", type: .resistanceWholeBody, muscle: .biceps, labels: [.repetitions, .weight, .intensity], properties: [])
        let givenLabels: [MKExerciseLabel] = [.repetitions(repetitions: 10), .intensity(intensity: 0.6), .weight(weight: 40)]

        // start a new session, adding one exercise
        let sessionId = try! app.startSession(.adHoc(exerciseType: .resistanceTargeted(muscleGroups: [.arms, .chest])))
        app.currentSession!.addExerciseDetail(givenDetail, labels: givenLabels, start: Date(), duration: 10)
        let (predicted1, _) = app.currentSession!.predictExerciseLabelsForExerciseDetail(givenDetail)
        XCTAssertEqual(givenLabels.filter { $0.descriptor != .intensity }.sorted { $0.0.id < $0.1.id }, predicted1.0.sorted { $0.0.id < $0.1.id })
        try! app.endCurrentSession()
        
        // try to load it
        let f = NSFetchRequest<MRManagedExerciseSession>(entityName: "MRManagedExerciseSession")
        f.predicate = Predicate(format: "id=%@", sessionId)
        let r = try! app.managedObjectContext.fetch(f).first!
        let e = (r.exercises.allObjects as! [MRManagedExercise]).first!
        let l = e.scalarLabels.allObjects as! [MRManagedExerciseScalarLabel]
        XCTAssertEqual(l.count, givenLabels.count)

        // start a different session but with the same exercise type
        try! app.startSession(.adHoc(exerciseType: .resistanceTargeted(muscleGroups: [.arms, .chest])))
        // expect the right preciction
        let bc = app.currentSession!.exerciseDetailsComingUp.first!
        XCTAssertEqual(bc.id, givenDetail.id)
        let (predicted2, _) = app.currentSession!.predictExerciseLabelsForExerciseDetail(bc)
        XCTAssertEqual(givenLabels.filter { $0.descriptor != .intensity }.sorted { $0.0.id < $0.1.id }, predicted2.0.sorted { $0.0.id < $0.1.id })
        try! app.endCurrentSession()
        
    }
    
}

