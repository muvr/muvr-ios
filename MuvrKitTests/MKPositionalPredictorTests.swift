import Foundation
import XCTest
@testable import MuvrKit

class MKPositionalPredictorTests : XCTestCase {

    func testPredictNext() {
        let values = (0..<100).map { Float($0) }
        let predictor = try! MKPredictor<Float>.positionalFromTrainingSet(values) { $0 }
        let prediction = predictor.predictNext(100)
        XCTAssertEqualWithAccuracy(prediction.first!, 100, accuracy: 0.5)
        XCTAssertEqualWithAccuracy(prediction.last!,  199, accuracy: 0.5)
    }
    
}

