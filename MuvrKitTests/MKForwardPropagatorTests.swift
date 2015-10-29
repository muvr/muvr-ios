import Foundation
import XCTest
@testable import MuvrKit

class MKForwardPropagatorTests : XCTestCase {
    
    var baseConfiguration = MKForwardPropagatorConfiguration(
        layerConfiguration: [2, 1],
        hiddenActivation: sigmoidActivation,
        outputActivation: sigmoidActivation,
        biasValue: 1.0,
        biasUnits: 1)
    
    let twoBinaryFeatures: [Float] = [1, 1,
                                      1, 0,
                                      0, 1,
                                      0, 0]
    
    ///
    /// AND matrix model test
    ///
    func testModelOfANDMatrix() {
        let model = try! MKForwardPropagator.configured(self.baseConfiguration, weights: [-30.0, 20.0, 20.0])
        let prediction = try! model.predictFeatureMatrix(twoBinaryFeatures)
        
        XCTAssertEqualWithAccuracy(prediction[0], 1, accuracy: 0.0001);
        XCTAssertEqualWithAccuracy(prediction[1], 0, accuracy: 0.0001);
        XCTAssertEqualWithAccuracy(prediction[2], 0, accuracy: 0.0001);
        XCTAssertEqualWithAccuracy(prediction[3], 0, accuracy: 0.0001);
    }
    
    ///
    /// OR matrix model test
    ///
    func testModelOfORMatrix() {
        let model = try! MKForwardPropagator.configured(self.baseConfiguration, weights: [-10.0, 20.0, 20.0])
        let prediction = try! model.predictFeatureMatrix(twoBinaryFeatures)
        
        XCTAssertEqualWithAccuracy(prediction[0], 1, accuracy: 0.0001);
        XCTAssertEqualWithAccuracy(prediction[1], 1, accuracy: 0.0001);
        XCTAssertEqualWithAccuracy(prediction[2], 1, accuracy: 0.0001);
        XCTAssertEqualWithAccuracy(prediction[3], 0, accuracy: 0.0001);
    }
    
    ///
    /// XNOR matrix model test
    ///
    func testModelOfXNORMatrix() {
        var conf = baseConfiguration
        conf.layerConfiguration = [2, 2, 1]
        
        let model = try! MKForwardPropagator.configured(conf, weights: [-30, 20, 20, 10, -20, -20, -10, 20, 20])
        let prediction = try! model.predictFeatureMatrix(twoBinaryFeatures)
        
        XCTAssertEqualWithAccuracy(prediction[0], 1, accuracy: 0.0001);
        XCTAssertEqualWithAccuracy(prediction[1], 0, accuracy: 0.0001);
        XCTAssertEqualWithAccuracy(prediction[2], 0, accuracy: 0.0001);
        XCTAssertEqualWithAccuracy(prediction[3], 1, accuracy: 0.0001);
    }
    
    ///
    /// Tangent activation test
    ///
    func testModelWithTangentOutput() {
        let features: [Float] = [4.8,  3.3,  1.3,  0.2]
        let conf = MKForwardPropagatorConfiguration(
            layerConfiguration: [4, 2, 3],
            hiddenActivation: tangentActivation,
            outputActivation: tangentActivation,
            biasValue: 1.0,
            biasUnits: 1)

        let model = try! MKForwardPropagator.configured(conf, weights: [
            -2.522616844907733, 1.379419132631195, 2.384441621038408, -4.411649980191586, -0.685608059818619,
            -10.887683996948859, -3.463033475731954, -3.561827798081323, 6.694420878577903, 5.847634136214969,
            -3.968908727857065, 8.456453936484778, -22.223450906514095, 8.545523821607908, -14.004325499443924,
            -16.865896703590984, -10.256283161547678, 3.198517762647665, 20.095491610370658])
        
        let prediction = try! model.predictFeatureMatrix(features)
        
        XCTAssertEqualWithAccuracy(prediction[0], 1,           accuracy: 0.000000001);
        XCTAssertEqualWithAccuracy(prediction[1], 0.999999999, accuracy: 0.000000001);
        XCTAssertEqualWithAccuracy(prediction[2], -1,          accuracy: 0.000000001);
    }
    
    
}