import XCTest

final class SmokeUITests: XCTestCase {
    func test_appLaunches() {
        let app = XCUIApplication.makeUnauthenticated()
        app.launch()
        XCTAssertEqual(app.state, .runningForeground)
    }
}
