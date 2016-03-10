import XCTest
@testable import MuvrKit

class MuvrUITests: XCTestCase {
        
    override func setUp() {
        super.setUp()
        
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        let app = XCUIApplication()
        
        app.launchArguments = ["--reset-container", "--default-data"]
        app.launch()

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }
    
    ///
    /// Starts a session of the given type:
    /// - click "Start another workout" button 
    /// - then select the given type from the table
    /// - and click the start button
    ///
    func startSession(app: XCUIApplication, sessionType: String) {
        NSThread.sleepForTimeInterval(0.1)
        // start another workout
        app.buttons["Start another workout"].tap()
        
        // start the Arms session
        let tablesQuery = app.tables
        tablesQuery.staticTexts[sessionType].tap()
        app.buttons["Start"].tap()
    }
    
    ///
    /// Swipe the specified scroll view until the given exercise button is found
    /// or the end is reached.
    /// - parameter scrollView: the name of the scrollview to swipe ("Coming up exercises" or "Alternatives exercises")
    ///
    func findExercise(app: XCUIApplication, scrollView: String, exerciseName: String) {
        var names = app.scrollViews[scrollView].buttons.allElementsBoundByIndex.map { $0.label }
        var lastName: String? = nil
        while !names.contains(exerciseName) && (lastName != names.last) {
            app.scrollViews[scrollView].swipeLeft()
            lastName = names.last
            names = app.scrollViews[scrollView].buttons.allElementsBoundByIndex.map { $0.label }
        }
    }
    
    func testArmsSessionWithNoExcerciseAllMissingLabels() {
        let app = XCUIApplication()
        
        startSession(app, sessionType: "Arms")
        
        // start the BBC exercise
        app.otherElements["Exercise control"].buttons["Barbell Biceps Curls"].tap()
        // go back
        app.otherElements["Exercise control"].buttons["Barbell Biceps Curls"].tap()
        // wait for > 5 s: we're now exercising
        NSThread.sleepForTimeInterval(5.1)
        app.otherElements["Exercise control"].buttons["Barbell Biceps Curls"].tap()

        // Wait for 30 seconds, then stop
        NSThread.sleepForTimeInterval(30)
        app.otherElements["Exercise control"].buttons["Barbell Biceps Curls"].tap()
        
        // Don't set any labels
        app.otherElements["Exercise control"].buttons["Barbell Biceps Curls"].tap()
        
        // Check that default labels are saved
        XCTAssertNotNil(app.otherElements["Repetitions"].value)
        XCTAssertNotNil(app.otherElements["Weight"].value)
        XCTAssertNotNil(app.otherElements["Duration"].value)
        
        // Stop session
        app.otherElements["Exercise control"].buttons["Barbell Biceps Curls"].pressForDuration(6)
    }
    
    func testAlternativeExercises() {
        let app = XCUIApplication()
        
        startSession(app, sessionType: "Arms")
        
        // swipe to find "Triceps dips"
        findExercise(app, scrollView: "Coming up exercises", exerciseName: "Triceps Dips")
        
        // click on "Triceps dips"
        app.scrollViews["Coming up exercises"].buttons["Triceps Dips"].tap()
        
        // swipe alternatives to find "Triceps extensions"
        findExercise(app, scrollView: "Alternatives exercises", exerciseName: "Triceps Extensions")
        
        // check alternatives contains "Triceps extension"
        let alternatives = app.scrollViews["Coming up exercises"].buttons.allElementsBoundByIndex.map { $0.label }
        XCTAssertTrue(alternatives.contains("Triceps Extensions"))
        
        // click on "Triceps extension"
        app.scrollViews["Alternatives exercises"].buttons["Triceps Extension"].tap()
        
        // start "triceps extension" exercise
        app.otherElements["Exercise control"].buttons["Triceps Extension"].tap()
    }
    
    func testTRXExercise() {
        let app = XCUIApplication()
        
        startSession(app, sessionType: "Core")
        
        // find "reverse plank"
        findExercise(app, scrollView: "Coming up exercises", exerciseName: "Trx Atomic Press")
        
        // start "reverse plank"
        app.scrollViews["Coming up exercises"].buttons["Trx Atomic Press"].tap()
        app.otherElements["Exercise control"].buttons["Trx Atomic Press"].tap()
        
        // wait 5 sec to pass "get ready" screen
        NSThread.sleepForTimeInterval(5.1)
        
        // train for 10 sec
        NSThread.sleepForTimeInterval(10)
        
        // end exercise
        app.otherElements["Exercise control"].buttons["Trx Atomic Press"].tap()
        
        // accept default labels
        app.otherElements["Exercise control"].buttons["Trx Atomic Press"].tap()
        
        // check there are only duration and repetitions labels
        let labels = app.otherElements.allElementsBoundByIndex.map { $0.label }
        XCTAssertTrue(labels.contains("Duration"))
        XCTAssertTrue(labels.contains("Repetitions"))
        XCTAssertFalse(labels.contains("Weight"))
        
        // Stop session
        app.otherElements["Exercise control"].buttons["Trx Atomic Press"].pressForDuration(6)
        
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
}
