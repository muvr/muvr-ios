import Foundation
import XCTest
import MuvrKit
@testable import Muvr

class MKExercisePlusExerciseIdTests : XCTestCase {
    
    func testCFESimple() {
        let (a, b, c) = MKExercise.componentsFromExerciseId("foo:bar")!
        XCTAssertEqual(a, "foo")
        XCTAssertEqual(b.first!, "bar")
        XCTAssertNil(c)
    }

    func testCFEMultiple() {
        let (a, b, c) = MKExercise.componentsFromExerciseId("foo:bar,baz/quux")!
        XCTAssertEqual(a, "foo")
        XCTAssertEqual(b.first!, "bar,baz")
        XCTAssertEqual(b.last!, "quux")
        XCTAssertNil(c)
    }

    func testCFEMultipleAtStation() {
        let (a, b, c) = MKExercise.componentsFromExerciseId("foo:bar,baz/quux@guillotine")!
        XCTAssertEqual(a, "foo")
        XCTAssertEqual(b.first!, "bar,baz")
        XCTAssertEqual(b.last!, "quux")
        XCTAssertEqual(c, "guillotine")
    }

}
