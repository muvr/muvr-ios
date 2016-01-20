import Foundation
import XCTest
@testable import MuvrKit

class MKMarkovPredictorPlusJSONTests : XCTestCase {

    func testJson() {
        let predictor = MKMarkovPredictor()
        predictor.trainPositional([10, 15, 20, 25, 20, 25], forExerciseId: "exerciseA")
        let nextValue = predictor.predictScalarForExerciseId("exerciseA", n: 7)
        let json = predictor.json
        
        let newPredictor = MKMarkovPredictor()
        newPredictor.mergeJSON(json)
        let newValue = predictor.predictScalarForExerciseId("exerciseA", n: 7)
        
        XCTAssertEqual(nextValue, newValue)
    }
}