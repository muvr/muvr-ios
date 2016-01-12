import Foundation
import XCTest
@testable import MuvrKit

extension MKMarkovTransitionSet : Equatable { }

func ==<State where State : Hashable>(lhs: MKMarkovTransitionSet<State>, rhs: MKMarkovTransitionSet<State>) -> Bool {
    for (k, vl) in lhs.transitionCounter {
        let vr = rhs.transitionCounter[k]
        if vl != vr { return false }
    }
    return true
}

class MKMarkovChainPlusJSONTests : XCTestCase {
    
    func testIdentity() {
        var c1: MKMarkovChain<String> = MKMarkovChain()
        let s = MKStateChain(states: ["a", "b", "c"])
        s.slices.forEach { slice in c1.addTransition(slice, next: "D") }
        
        let json = c1.json { $0 }
        let c2 = MKMarkovChain<String>.fromJson(json) { $0 as? String }!
    
        XCTAssertEqual(c1.transitionMap.count, c2.transitionMap.count)
        for (k, vl) in c1.transitionMap {
            let vr = c2.transitionMap[k]!
            XCTAssertEqual(vl, vr)
        }
    }
    
}
