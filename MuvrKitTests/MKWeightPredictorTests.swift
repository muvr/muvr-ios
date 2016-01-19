import Foundation
import XCTest
@testable import MuvrKit

class MKWeightPredictorTests : XCTestCase {

    func roundValue(value: Double, forExerciseId exerciseId: MKExercise.Id) -> Double {
        return MKScalarRounderFunction.roundMinMax(value, minimum: 2.5, step: 2.5, maximum: nil)
    }

    func testPeriod() {
        let predictor = MKPolynomialFittingScalarPredictor(round: roundValue)
        XCTAssertTrue(predictor.checkPeriod([10.0, 12, 12, 14, 16, 16, 15, 11]))
        XCTAssertTrue(predictor.checkPeriod([1.0, 2, 3, 4, 5, 6, 7, 7, 6, 2]))
        XCTAssertFalse(predictor.checkPeriod([15.0, 20, 25, 30, 25, 20, 15, 10]))
    }

    func insertSequence<E>(plan: MKExercisePlan<E>, sequence: [E]) {
        for value in sequence {
            plan.insert(value)
        }
    }

    func testSequence(sequence: [Double], desiredValue: Double) {
        let plan = MKExercisePlan<Double>()
        insertSequence(plan, sequence: sequence)
        XCTAssertEqual(plan.next.first, desiredValue)
    }

    func testPredictWithMarkov() {
        testSequence([10.0, 15, 20, 25, 30, 35, 30, 30, 15, 20], desiredValue: 25)

        testSequence([10, 12.5, 15, 17.5, 17.5, 15, 15, 15, 12.5, 12.5, 12.5, 10, 10, 13], desiredValue: 12.5)

        testSequence([10.0, 15, 20, 25, 30, 35, 30, 30, 10.0, 15, 20, 25, 30, 35], desiredValue: 30)

        testSequence([10.0, 15, 20, 25, 30, 35, 30, 30, 10.0, 15, 20, 25, 30, 35, 30, 30, 10, 10, 10], desiredValue: 10)

    }

    func trainSequential(predictor: MKScalarPredictor, trainingSet: [Double], id: String) {
        guard trainingSet.count >= 1 else { return }
        (1...trainingSet.count).forEach { size in
            let sliceData = trainingSet[0..<size]
            predictor.trainPositional(Array(sliceData), forExerciseId: id)
        }
    }

    func testBigDrop1() {
        let predictor = MKPolynomialFittingScalarPredictor(round: roundValue)
        let sequence = [10.0, 12, 12, 14, 16, 16, 15, 9]
        trainSequential(predictor, trainingSet: sequence, id: "biceps-curl")
        let nextValue = predictor.predictScalarForExerciseId("biceps-curl", n: sequence.count)
        XCTAssertNotEqual(nextValue, 2.5)
        XCTAssertTrue(nextValue >= 9  && nextValue <= 14)
    }

    func testBigDrop2() {
        let predictor = MKPolynomialFittingScalarPredictor(round: roundValue)
        let sequence = [10.0, 15, 20, 25, 30, 35, 30, 30, 9, 13]
        trainSequential(predictor, trainingSet: sequence, id: "biceps-curl")
        let nextValue = predictor.predictScalarForExerciseId("biceps-curl", n: sequence.count)
        XCTAssertNotEqual(nextValue, 152.5)
        XCTAssertTrue(nextValue >= 13  && nextValue <= 25)
    }

    func testHighJump1() {
        let predictor = MKPolynomialFittingScalarPredictor(round: roundValue)
        let sequence = [10.0, 15, 20, 25, 30, 35, 30, 30]
        trainSequential(predictor, trainingSet: sequence, id: "biceps-curl")
        let nextValue = predictor.predictScalarForExerciseId("biceps-curl", n: sequence.count)
        XCTAssertNotEqual(nextValue, 72.5)
        XCTAssertTrue(nextValue >= 5  && nextValue <= 40)
    }

    func testHighJump2() {
        let predictor = MKPolynomialFittingScalarPredictor(round: roundValue)
        let sequence = [15.0, 20, 25, 30, 35, 40, 35, 35]
        trainSequential(predictor, trainingSet: sequence, id: "biceps-curl")
        let nextValue = predictor.predictScalarForExerciseId("biceps-curl", n: sequence.count)
        XCTAssertNotEqual(nextValue, 77.5)
        XCTAssertTrue(nextValue >= 10  && nextValue <= 45)
    }
}