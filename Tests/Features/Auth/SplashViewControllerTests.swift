import XCTest
@testable import SushiGarden

final class SplashViewControllerTests: XCTestCase {
    func test_onContinue_isCalledAfterConfiguredDelay() {
        let exp = expectation(description: "onContinue called")
        let sut = SplashViewController(splashDelay: 0.05)
        sut.onContinue = { exp.fulfill() }
        sut.loadViewIfNeeded()
        sut.viewDidAppear(false)
        wait(for: [exp], timeout: 1.0)
    }

    func test_view_hasCorrectBackgroundColor() {
        let sut = SplashViewController()
        sut.loadViewIfNeeded()
        XCTAssertEqual(sut.view.backgroundColor, AppColor.background)
    }
}
