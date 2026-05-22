import XCTest
@testable import SushiGarden

final class RegisterViewControllerTests: XCTestCase {
    func test_loadsWithoutCrashing() {
        let vm = RegisterViewModel(auth: InMemoryAuthService())
        let sut = RegisterViewController(viewModel: vm)
        sut.loadViewIfNeeded()
        XCTAssertNotNil(sut.view)
    }

    func test_viewModel_isExposed() {
        let vm = RegisterViewModel(auth: InMemoryAuthService())
        let sut = RegisterViewController(viewModel: vm)
        XCTAssertTrue(sut.viewModel === vm)
    }
}
