import XCTest
@testable import SushiGarden

final class LoginViewControllerTests: XCTestCase {
    func test_loadsWithoutCrashing() {
        let vm = LoginViewModel(auth: InMemoryAuthService())
        let sut = LoginViewController(viewModel: vm)
        sut.loadViewIfNeeded()
        XCTAssertNotNil(sut.view)
    }

    func test_viewModel_isExposed() {
        let vm = LoginViewModel(auth: InMemoryAuthService())
        let sut = LoginViewController(viewModel: vm)
        XCTAssertTrue(sut.viewModel === vm)
    }
}
