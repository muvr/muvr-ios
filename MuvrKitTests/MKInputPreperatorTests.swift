import Foundation
import XCTest
@testable import MuvrKit

class MKInputPreperatorTests : XCTestCase {
    lazy var preperator: MKInputPreparator = MKInputPreparator()
    
    func testScaling() {
        let block: [Float] = [-4, 4, 0, 1, -1, 0.5, -0.5]
        let scaled = preperator.scale(block, range: 8.0)
        XCTAssertEqual(scaled, [-1, 1, 0, 0.25, -0.25, 0.125, -0.125])
    }
    
    func testHighpassfilter() {
        let numValues = 100
        let data: [Float] = (0...numValues).map{ Float($0) / 100 }
        let noisyData: [Float] = (0...numValues).map{ Float($0) / 100 + sin(Float($0)) / 50}
        let filtered = preperator.highpassfilter(noisyData, rate: 1/100, freq: 1/10)

        // First value should always be unchanged
        XCTAssertEqual(filtered[0], data[0])
        
        for i in 0..<numValues-1{
            // Filtered signal should be monotonically increasing
            XCTAssertLessThan(filtered[i], filtered[i+1])
            // Filtered signal should be roughly equal to the incoming data
            XCTAssertEqualWithAccuracy(filtered[i+1], data[i+1], accuracy: Float(0.15))
        }
    }
}