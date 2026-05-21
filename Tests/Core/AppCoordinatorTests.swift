import XCTest
@testable import SushiGarden

final class AppCoordinatorTests: XCTestCase {
    func test_start_whenUnauthenticated_setsAuthPlaceholderRoot() {
        let window = UIWindow()
        let container = AppContainer()      // seeded auth = logged out
        let sut = AppCoordinator(window: window, container: container)

        sut.start()

        XCTAssertTrue(window.rootViewController is AuthPlaceholderViewController)
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
