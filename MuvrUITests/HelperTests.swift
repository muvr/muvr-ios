import Foundation
import XCTest

public class UIHelper {
    static public func startExercise(app: XCUIApplication, plan: [String], exercise: String) {
        
        let app = XCUIApplication()
        let tablesQuery = app.tables
        
        // Select Exercise Type and start session
        for muscle in plan {
            tablesQuery.staticTexts[muscle].tap()
        }
        
        app.buttons["Start"].tap()
        
        // Select certain exercise in scroll views
        app.scrollViews.buttons[exercise].tap()
        
        // Tap exercise
        let element = app.otherElements["Exercise control"]
        let exerciseButton = element.buttons[exercise]
        exerciseButton.tap()
        
        // Wait a few second to bypass the Get Ready view
        NSThread.sleepForTimeInterval(7)
        
        // Go to finish view (modify weight/rep/inten)
        exerciseButton.tap()
        
        // Modify the weight
        let weightElement = tablesQuery.cells.elementBoundByIndex(1)
        let addButton = weightElement.buttons.elementBoundByIndex(1)
        let minusButton = weightElement.buttons.elementBoundByIndex(0)

        // Increase/Decrease 1 unit
        addButton.tap()
        minusButton.tap()

        
        // Finish the exercise
        exerciseButton.tap()
    }
}
