import XCTest

final class TabBarUITests: XCTestCase {
    func testMainTabsExist() throws {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.tabBars.buttons["Home"].exists)
        XCTAssertTrue(app.tabBars.buttons["Journal"].exists)
        XCTAssertTrue(app.tabBars.buttons["Focus"].exists)
        XCTAssertTrue(app.tabBars.buttons["Insights"].exists)
        XCTAssertTrue(app.tabBars.buttons["Health"].exists)
        XCTAssertTrue(app.tabBars.buttons["Settings"].exists)
    }
}
