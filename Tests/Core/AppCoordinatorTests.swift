import XCTest
@testable import SushiGarden

final class AppCoordinatorTests: XCTestCase {
    func test_start_whenUnauthenticated_setsNavControllerAsRoot() {
        let window = UIWindow()
        let auth = InMemoryAuthService()
        let container = AppContainer(auth: auth)
        let sut = AppCoordinator(window: window, container: container)
        sut.start()
        XCTAssertTrue(window.rootViewController is UINavigationController)
    }

    func test_start_whenUnauthenticated_showsSplashInNav() {
        let window = UIWindow()
        let auth = InMemoryAuthService()
        let container = AppContainer(auth: auth)
        let sut = AppCoordinator(window: window, container: container)
        sut.start()
        let nav = window.rootViewController as? UINavigationController
        XCTAssertTrue(nav?.topViewController is SplashViewController)
    }

    func test_whenAuthenticationSucceeds_swapsToMainPlaceholderRoot() {
        let window = UIWindow()
        let auth = InMemoryAuthService()
        let container = AppContainer(auth: auth)
        let sut = AppCoordinator(window: window, container: container)
        sut.start()
        _ = auth.login(email: "test@sushi.ru", password: "secret1")
        XCTAssertTrue(window.rootViewController is MainPlaceholderViewController)
    }
}
