import XCTest
@testable import MuvrKit

class MRExerciseViewTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
       
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        XCUIApplication().launch()

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testIncrementWeight() {

        let app = XCUIApplication()
        let tablesQuery = app.tables
        
        // Select Exercise Type and start session
        tablesQuery.staticTexts["Arms"].tap()
        app.buttons["Start"].tap()
        
        // Select certain exercise in scroll views
        app.scrollViews.buttons["Biceps Curls"].tap()
        
        // Tap exercise
        let element = app.childrenMatchingType(.Window).elementBoundByIndex(0).childrenMatchingType(.Other).element.childrenMatchingType(.Other).element.childrenMatchingType(.Other).elementBoundByIndex(1)
        let bicepsCurlsButton = element.buttons["Biceps Curls"]
        bicepsCurlsButton.tap()
        
        // Waiting a few second to bypass the Get Ready view
        sleep(7)
        
        // Go to finish view
        bicepsCurlsButton.tap()
        

        // Modify the weight
        let weightElement = tablesQuery.cells.elementBoundByIndex(1)
        let addButton = weightElement.buttons.elementBoundByIndex(1)
        let minusButton = weightElement.buttons.elementBoundByIndex(0)
        let currentWeight = Float(weightElement.staticTexts.element.label)
        
        // Increase/Decrease 1 unit
        addButton.tap()
        let incrementWeight = Float(weightElement.staticTexts.element.label)
        XCTAssertEqual(incrementWeight, currentWeight! + 0.5)
        
        minusButton.tap()
        let decrementWeight = Float(weightElement.staticTexts.element.label)
        XCTAssertEqual(decrementWeight, currentWeight)
        
        // Hold for a few seconds
        addButton.pressForDuration(2)
        let newWeight = Float(weightElement.staticTexts.element.label)
        XCTAssertEqual(newWeight, currentWeight! + 21)

        minusButton.pressForDuration(2)
        let newWeight2 = Float(weightElement.staticTexts.element.label)
        XCTAssertEqual(newWeight2, currentWeight)
        
        // Finish the exercise
        bicepsCurlsButton.tap()
    }

}
