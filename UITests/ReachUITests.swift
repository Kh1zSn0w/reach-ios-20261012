import XCTest

final class ReachUITests: XCTestCase {
    func capture(_ name: String, app: XCUIApplication) {
        let attachment = XCTAttachment(screenshot: app.screenshot()); attachment.name = name; attachment.lifetime = .keepAlways; add(attachment)
    }
    func testScreensAndTemptationFlow() {
        let app = XCUIApplication(); app.launch()
        if app.buttons["Close"].waitForExistence(timeout: 8) { app.buttons["Close"].tap() }
        XCTAssertTrue(app.buttons["Today"].waitForExistence(timeout: 8)); capture("01-Today", app: app)
        app.buttons["Body"].tap(); XCTAssertTrue(app.buttons["Log food"].waitForExistence(timeout: 5)); capture("02-Body", app: app)
        app.buttons["Open Cut Mode questionnaire"].tap(); XCTAssertTrue(app.staticTexts["CUT\nWITH\nCONTROL."].waitForExistence(timeout: 5)); capture("03-Cut", app: app); app.buttons["Done"].tap()
        app.buttons["Relapse"].tap(); XCTAssertTrue(app.buttons["I’m tempted"].waitForExistence(timeout: 5)); capture("04-Recovery", app: app)
        app.buttons["I’m tempted"].tap(); XCTAssertTrue(app.buttons["I’ve stepped away"].waitForExistence(timeout: 5)); capture("05-Interrupt", app: app)
        app.buttons["I’ve stepped away"].tap(); XCTAssertTrue(app.buttons["Next: change my environment"].waitForExistence(timeout: 5)); capture("06-Breathe", app: app)
        app.buttons["Next: change my environment"].tap(); XCTAssertTrue(app.buttons["Commit to ten minutes"].waitForExistence(timeout: 5)); app.buttons["Commit to ten minutes"].tap()
        XCTAssertTrue(app.buttons["I interrupted the urge"].waitForExistence(timeout: 5)); app.buttons["I interrupted the urge"].tap(); app.buttons["Back to my day"].tap()
        app.buttons["Rewire"].tap(); XCTAssertTrue(app.buttons["Start focus session"].waitForExistence(timeout: 5)); capture("07-Rewire", app: app)
        app.buttons["Resolve"].tap(); XCTAssertTrue(app.buttons["Next quote"].waitForExistence(timeout: 5)); capture("08-Resolve", app: app)
        app.buttons["Next quote"].tap(); app.buttons["Favorite quote"].tap(); capture("09-Quote", app: app)
    }
    func testFoodLogPersists() {
        let app = XCUIApplication(); app.launch()
        if app.buttons["Close"].waitForExistence(timeout: 3) { app.buttons["Close"].tap() }
        app.buttons["Body"].tap(); app.buttons["Log food"].tap()
        let name = app.textFields["Food name"]; XCTAssertTrue(name.waitForExistence(timeout: 5)); name.tap(); name.typeText("Test yogurt")
        let grams = app.textFields["Portion weight (g)"]; grams.tap(); grams.typeText("150")
        let kcal = app.textFields["Calories per 100 g"]; kcal.tap(); kcal.typeText("200")
        app.swipeUp(); app.buttons["Add to food log"].tap()
        app.swipeUp(); XCTAssertTrue(app.staticTexts["Test yogurt"].waitForExistence(timeout: 5))
        app.terminate(); app.launch(); app.buttons["Body"].tap(); app.swipeUp(); XCTAssertTrue(app.staticTexts["Test yogurt"].waitForExistence(timeout: 5))
        capture("10-Persisted-food", app: app)
    }
}
