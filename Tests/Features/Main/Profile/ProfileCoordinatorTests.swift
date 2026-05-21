import XCTest
@testable import SushiGarden

final class ProfileCoordinatorTests: XCTestCase {
    private func makeSUT(
        onLogout: @escaping () -> Void = {}
    ) -> (ProfileCoordinator, UINavigationController) {
        let nav = UINavigationController()
        let sut = ProfileCoordinator(
            navigationController: nav,
            container: AppContainer(),
            onLogout: onLogout)
        return (sut, nav)
    }

    func test_start_setsProfileViewControllerAsRoot() {
        let (sut, nav) = makeSUT()
        sut.start()
        XCTAssertTrue(nav.topViewController is ProfileViewController)
    }

    func test_logout_callsOnLogout() {
        var loggedOut = false
        let auth = InMemoryAuthService()
        _ = auth.login(email: "test@sushi.ru", password: "secret1")
        let container = AppContainer(auth: auth)
        let nav = UINavigationController()
        let sut = ProfileCoordinator(
            navigationController: nav,
            container: container,
            onLogout: { loggedOut = true })
        sut.start()
        let profileVC = nav.topViewController as? ProfileViewController
        profileVC?.viewModel.logout()
        XCTAssertTrue(loggedOut)
    }
}
