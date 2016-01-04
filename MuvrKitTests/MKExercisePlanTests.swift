import Foundation
import XCTest
@testable import MuvrKit

class MKExercisePlanTests : XCTestCase {

    func evaluatePlan(exerciseIds: [MKExerciseId]) -> (Double, Double) {
        let exercises = exerciseIds
        let plan = MKExercisePlan<String>()
        let estimates: [Bool] = (0..<exercises.count - 1).map { i in
            let completed = exercises[i]
            let expected = exercises[i + 1]
            plan.addExercise(completed)
         
            return plan.nextExercises.first.map { $0 == expected} ?? true
        }
        let successes = Double(estimates.filter { $0 == true }.count)
        let failures  = Double(estimates.filter { $0 == false }.count)
        let count     = Double(exercises.count)

        return (successes / count, failures / count)
    }
    
    func testArmsAtHome() {
        let (s, f) = evaluatePlan([
            "triceps-extension", "biceps-curl", "biceps-curl", "biceps-curl",       "triceps-extension", "biceps-curl",
            "triceps-extension", "biceps-curl", "triceps-extension", "biceps-curl", "triceps-extension", "biceps-curl",
            "triceps-extension", "biceps-curl", "triceps-extension", "biceps-curl", "triceps-extension", "triceps-extension",
            "biceps-curl", "triceps-extension", "biceps-curl", "triceps-extension", "biceps-curl", "triceps-extension",
            "biceps-curl", "triceps-extension", "biceps-curl", "triceps-extension", "biceps-curl", "triceps-extension",
            "biceps-curl", "triceps-extension", "biceps-curl", "triceps-extension", "biceps-curl", "triceps-extension",
            "biceps-curl", "triceps-extension", "biceps-curl", "triceps-extension", "biceps-curl", "triceps-extension"])
        XCTAssertGreaterThan(s, 0.85)
        XCTAssertLessThan(f, 0.1)
    }
    
}
