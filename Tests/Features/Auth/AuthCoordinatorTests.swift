import XCTest
@testable import SushiGarden

final class AuthCoordinatorTests: XCTestCase {
    private func makeSUT(container: AppContainer = AppContainer()) -> (AuthCoordinator, UINavigationController) {
        let nav = UINavigationController()
        let sut = AuthCoordinator(navigationController: nav, container: container)
        return (sut, nav)
    }

    func test_start_setsSplashAsRoot() {
        let (sut, nav) = makeSUT()
        sut.start()
        XCTAssertTrue(nav.topViewController is SplashViewController)
    }

    func test_afterSplash_showsLogin() {
        let (sut, nav) = makeSUT()
        sut.start()
        let splash = nav.topViewController as? SplashViewController
        splash?.onContinue?()
        XCTAssertTrue(nav.topViewController is LoginViewController)
    }

    func test_fromLogin_toggleToRegister_showsRegister() {
        let (sut, nav) = makeSUT()
        sut.start()
        (nav.topViewController as? SplashViewController)?.onContinue?()
        (nav.topViewController as? LoginViewController)?.viewModel.goToRegister()
        XCTAssertTrue(nav.topViewController is RegisterViewController)
    }

    func test_fromRegister_toggleToLogin_showsLogin() {
        let (sut, nav) = makeSUT()
        sut.start()
        (nav.topViewController as? SplashViewController)?.onContinue?()
        (nav.topViewController as? LoginViewController)?.viewModel.goToRegister()
        (nav.topViewController as? RegisterViewController)?.viewModel.goToLogin()
        XCTAssertTrue(nav.topViewController is LoginViewController)
    }
}
