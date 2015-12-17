import Foundation
import XCTest
@testable import MuvrKit

class MKMarkovChainTests : XCTestCase {
    private let allLabels = ["biceps-curl", "triceps-extension", "lateral-raise"]
    private let armsStates = [
        "triceps-extension", "biceps-curl", "biceps-curl", "biceps-curl",       "triceps-extension", "biceps-curl",
        "triceps-extension", "biceps-curl", "triceps-extension", "biceps-curl", "triceps-extension", "biceps-curl",
        "triceps-extension", "biceps-curl", "triceps-extension", "biceps-curl", "triceps-extension", "triceps-extension",
        "biceps-curl", "triceps-extension", "biceps-curl", "triceps-extension", "biceps-curl", "triceps-extension",
        "biceps-curl", "triceps-extension", "biceps-curl", "triceps-extension", "biceps-curl", "triceps-extension",
        "biceps-curl", "triceps-extension", "biceps-curl", "triceps-extension", "biceps-curl", "triceps-extension",
        "biceps-curl", "triceps-extension", "biceps-curl", "triceps-extension", "biceps-curl", "triceps-extension"]
    
    func testX() {
        var c: MKMarkovChain<String> = MKMarkovChain()
        let s = MKStateChain(states: armsStates)
        c.addTransition(s, next: "biceps-curl")

        for s1 in allLabels {
            for s2 in allLabels {
                let prob = c.transitionProbability(s1, state2: s2)
                print("\(s1) -> \(s2): \(prob)")
            }
        }
        
    }
    
}
