import Foundation
import XCTest
@testable import MuvrKit

class MKExerciseDetailTests : XCTestCase {

    func testAlternateExercises() {
        let dumbbellBicepsCurl = MKExerciseDetail(id: "dumbbell-biceps-curl", type: .ResistanceTargeted(muscleGroups: [.Arms]), muscle: .Biceps, labels: [.Repetitions, .Weight], properties: [])
        let tricepsDips = MKExerciseDetail(id: "triceps-dips", type: .ResistanceTargeted(muscleGroups: [.Arms]), muscle: .Triceps, labels: [.Repetitions, .Weight], properties: [])
        let barbellBicepsCurl = MKExerciseDetail(id: "barbell-biceps-curl", type: .ResistanceTargeted(muscleGroups: [.Arms]), muscle: .Biceps, labels: [.Repetitions, .Weight], properties: [])
        let legPress = MKExerciseDetail(id: "legPress", type: .ResistanceTargeted(muscleGroups: [.Legs]), muscle: .Quadriceps, labels: [.Repetitions, .Weight], properties: [])
        let treadMill = MKExerciseDetail(id: "treadmill", type: .IndoorsCardio, muscle: nil, labels: [], properties: [])
        let stepper = MKExerciseDetail(id: "stepper", type: .IndoorsCardio, muscle: nil, labels: [], properties: [])
        
        let exercises = [dumbbellBicepsCurl, tricepsDips, barbellBicepsCurl, treadMill, stepper]
        XCTAssertEqual(["dumbbell-biceps-curl", "barbell-biceps-curl"], exercises.filter { $0.isAlternativeOf(barbellBicepsCurl) }.map { $0.id })
        XCTAssertEqual(["triceps-dips"], exercises.filter { $0.isAlternativeOf(tricepsDips) }.map { $0.id })
        XCTAssertEqual([], exercises.filter { $0.isAlternativeOf(legPress) }.map { $0.id })
        XCTAssertEqual(["treadmill", "stepper"], exercises.filter { $0.isAlternativeOf(treadMill) }.map { $0.id })
    }
    
}