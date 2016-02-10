import Foundation
import XCTest
@testable import MuvrKit

class MKRepeatLabelsPredictorTests: XCTestCase {

    func testPredictor() {
        let predictor = MKRepeatLabelsPredictor()
        XCTAssertNil(predictor.predictLabels(forExercise: "warmup"))
        
        predictor.correctLabels(forExercise: "warmup", labels: ([.Intensity(intensity: 0.4), .Repetitions(repetitions: 10)], 30))
        
        let (labels, duration) = predictor.predictLabels(forExercise: "warmup")!
        
        XCTAssertEqual(30, duration)
        labels.forEach {
            switch $0 {
                case .Intensity(let i): XCTAssertEqual(0.4, i)
                case .Repetitions(let r): XCTAssertEqual(10, r)
                default: XCTFail("Unexpected label: \($0.id)")
            }
        }
    }
    
    func testSerialization() {
        let predictor = MKRepeatLabelsPredictor()
        predictor.correctLabels(forExercise: "warmup", labels: ([.Intensity(intensity: 0.4), .Repetitions(repetitions: 10)], 30))
        
        let state = predictor.state
        XCTAssertNotNil(state["warmup"])
        let labels = state["warmup"]!
        XCTAssertEqual(0.4, labels["intensity"]!)
        XCTAssertEqual(10, labels["repetitions"]!)
        XCTAssertEqual(30, labels["duration"]!)
        
        
        let json = predictor.json
        XCTAssertGreaterThan(json.length, 0)
        let restored = MKRepeatLabelsPredictor(fromJson: json)
        XCTAssertNotNil(restored)
        
        let (ls, d) = restored!.predictLabels(forExercise: "warmup")!
        
        XCTAssertEqual(30, d)
        ls.forEach {
            switch $0 {
            case .Intensity(let i): XCTAssertEqual(0.4, i)
            case .Repetitions(let r): XCTAssertEqual(10, r)
            default: XCTFail("Unexpected label: \($0.id)")
            }
        }
    }
    
}