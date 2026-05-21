import XCTest
@testable import SushiGarden

final class ProfileViewModelTests: XCTestCase {
    private func makeLoggedInAuth() -> InMemoryAuthService {
        let auth = InMemoryAuthService()
        _ = auth.login(email: "test@sushi.ru", password: "secret1")
        return auth
    }

    func test_profile_exposesCurrentUser() {
        let auth = makeLoggedInAuth()
        let sut = ProfileViewModel(auth: auth)
        XCTAssertEqual(sut.profile, auth.currentUser)
    }

    func test_logout_callsAuthLogout() {
        let auth = makeLoggedInAuth()
        let sut = ProfileViewModel(auth: auth)
        sut.logout()
        XCTAssertFalse(auth.isAuthenticated)
        XCTAssertNil(auth.currentUser)
    }

    func test_logout_firesOnLogoutCompleted() {
        let auth = makeLoggedInAuth()
        let sut = ProfileViewModel(auth: auth)
        var called = false
        sut.onLogoutCompleted = { called = true }
        sut.logout()
        XCTAssertTrue(called)
    }
}
