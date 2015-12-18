import Foundation
import XCTest
@testable import MuvrKit

class MKStateChainTests : XCTestCase {

    func testSlices() {
        let sc: MKStateChain<String> = MKStateChain(states: ["a", "b", "c", "d"])
        XCTAssertEqual(sc.slices[0], MKStateChain(states: ["a", "b", "c", "d"]))
        XCTAssertEqual(sc.slices[1], MKStateChain(states: [     "b", "c", "d"]))
        XCTAssertEqual(sc.slices[2], MKStateChain(states: [          "c", "d"]))
        XCTAssertEqual(sc.slices[3], MKStateChain(states: [               "d"]))
    }
    
}
