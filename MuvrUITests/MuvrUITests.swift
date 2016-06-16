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
    /// - parameter app: The iOS application
    /// - parameter workoutType: "Custom" or "Library"
    /// - parameter sessionType: if library workout: the workout name, 
    ///                          if custom workout: the main exercise type of the session
    ///
    func startSession(_ app: XCUIApplication, workoutType: String, sessionType: String) {
        Thread.sleep(forTimeInterval: 0.1)
        
        // swipe to "Start another workout"
        swipeTo(app, scrollView: "Workouts", target: "Start another workout")
        
        // start another workout
        app.buttons["Start another workout"].tap()
        
        // select the custom workout
        app.segmentedControls["Workout control"].buttons[workoutType].tap()
        
        // start the Arms session
        let tablesQuery = app.tables
        tablesQuery.staticTexts[sessionType].tap()
        app.buttons["Start"].tap()
    }
    
    ///
    /// Swipe the specified scroll view until the given exercise button is found
    /// or the end is reached.
    /// - parameter scrollView: the name of the scrollview to swipe 
    /// - parameter target: the name of the button to look for
    ///
    func swipeTo(_ app: XCUIApplication, scrollView: String, target: String) {
        var names = app.scrollViews[scrollView].buttons.allElementsBoundByIndex.map { $0.label }
        var lastName: String? = nil
        while !names.contains(target) && (lastName != names.last) {
            app.scrollViews[scrollView].swipeLeft()
            lastName = names.last
            names = app.scrollViews[scrollView].buttons.allElementsBoundByIndex.map { $0.label }
        }
    }
    
    
    ///
    /// swipe main button until the given exercise is found
    /// - parameter exerciseName: the name of the exercise to look for
    ///
    func swipeToExercise(_ app: XCUIApplication, exerciseName: String) {
        let first = app.otherElements["Exercise control"].buttons.allElementsBoundByIndex.first?.label ?? ""
        var current: String = ""
        while (current != exerciseName && current != first) {
            app.otherElements["Exercise control"].swipeLeft()
            current = app.otherElements["Exercise control"].buttons.allElementsBoundByIndex.first?.label ?? ""
        }
    }
    
    func testArmsSessionWithNoExcerciseAllMissingLabels() {
        let app = XCUIApplication()
        
        startSession(app, workoutType: "Custom", sessionType: "Arms")
        
        // start the BBC exercise
        app.otherElements["Exercise control"].buttons["Barbell Biceps Curls"].tap()
        // go back
        app.otherElements["Exercise control"].buttons["Barbell Biceps Curls"].tap()
        // wait for > 5 s: we're now exercising
        Thread.sleep(forTimeInterval: 5.1)
        app.otherElements["Exercise control"].buttons["Barbell Biceps Curls"].tap()
        
        // long press while exercising -> shouldn't do anything
        app.otherElements["Exercise control"].buttons["Barbell Biceps Curls"].press(forDuration: 6)

        // Wait for 20 more seconds, then stop
        Thread.sleep(forTimeInterval: 20)
        app.otherElements["Exercise control"].buttons["Barbell Biceps Curls"].tap()
        
        // Don't set any labels
        app.otherElements["Exercise control"].buttons["Barbell Biceps Curls"].tap()
        
        // Check that default labels are saved
        XCTAssertNotNil(app.otherElements["Repetitions"].value)
        XCTAssertNotNil(app.otherElements["Weight"].value)
        XCTAssertNotNil(app.otherElements["Duration"].value)
        
        // Stop session
        app.otherElements["Exercise control"].buttons["Barbell Biceps Curls"].press(forDuration: 6)
    }
    
    func testAlternativeExercises() {
        let app = XCUIApplication()
        
        startSession(app, workoutType: "Custom", sessionType: "Arms")
        
        // swipe to find "Triceps dips"
        swipeTo(app, scrollView: "Coming up exercises", target: "Triceps Dips")
        
        // click on "Triceps dips"
        app.scrollViews["Coming up exercises"].buttons["Triceps Dips"].tap()
        
        // swipe alternatives to find "Triceps extensions"
        swipeToExercise(app, exerciseName: "Trx Triceps Press")
        
        // start "triceps extension" exercise
        app.otherElements["Exercise control"].buttons["Trx Triceps Press"].tap()
    }
    
    func testTRXExercise() {
        let app = XCUIApplication()
        
        startSession(app, workoutType: "Custom", sessionType: "Core")
        
        // find "reverse plank"
        swipeTo(app, scrollView: "Coming up exercises", target: "Trx Atomic Press")
        
        // start "reverse plank"
        app.scrollViews["Coming up exercises"].buttons["Trx Atomic Press"].tap()
        app.otherElements["Exercise control"].buttons["Trx Atomic Press"].tap()
        
        // wait 5 sec to pass "get ready" screen
        Thread.sleep(forTimeInterval: 5.1)
        
        // train for 10 sec
        Thread.sleep(forTimeInterval: 10)
        
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
        app.otherElements["Exercise control"].buttons["Trx Atomic Press"].press(forDuration: 6)
    }
    
    func testLibraryTRXWorkout() {
        let app = XCUIApplication()
        startSession(app, workoutType: "Library", sessionType: "TRX workout")
        // Stop session
        app.otherElements["Exercise control"].buttons["Trx Biceps Curl"].press(forDuration: 6)
    }

    func testDefaultWorkout() {
        let app = XCUIApplication()
        
        Thread.sleep(forTimeInterval: 1)
        
        // start default workout
        app.otherElements["Workout control"].buttons["Full body workout"].tap()
        
        Thread.sleep(forTimeInterval: 0.1)
        
        // stop session
        app.otherElements["Exercise control"].buttons["Dumbbell Shoulder Press"].press(forDuration: 6)
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
}
