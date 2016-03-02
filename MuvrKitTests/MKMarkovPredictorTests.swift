import Foundation
import XCTest
@testable import MuvrKit

class MKMarkovPredictorTests : XCTestCase {

    func evaluatePlan(exerciseIds: [MKExercise.Id]) -> (Double, Double) {
        let exercises = exerciseIds
        let plan = MKMarkovPredictor<String>()
        let estimates: [Bool] = (0..<exercises.count - 1).map { i in
            let completed = exercises[i]
            let expected = exercises[i + 1]
            plan.insert(completed)
            
            return plan.next.first.map { $0 == expected} ?? true
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
        XCTAssertGreaterThan(s, 0.80)
        XCTAssertLessThan(f, 0.2)
    }
    
    func testNextReturnsAllKnownStates() {
        let p = MKMarkovPredictor<Int>()
        XCTAssertEqual(p.next.count, 0)
        
        for s in 1..<50 {
            p.insert(s)
            XCTAssertEqual(p.next.count, s)
        }
    }
    
}
