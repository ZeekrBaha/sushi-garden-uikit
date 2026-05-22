import XCTest
import Combine
@testable import SushiGarden

final class InMemoryAuthServiceTests: XCTestCase {
    private var cancellables = Set<AnyCancellable>()

    func test_login_withSeededCredentials_succeedsAndPublishesAuthenticated() {
        let auth = InMemoryAuthService()
        var states: [Bool] = []
        auth.isAuthenticatedPublisher.sink { states.append($0) }.store(in: &cancellables)

        let result = auth.login(email: "test@sushi.ru", password: "secret1")

        switch result {
        case .success(let user): XCTAssertEqual(user.email, "test@sushi.ru")
        case .failure: XCTFail("expected success")
        }
        XCTAssertTrue(auth.isAuthenticated)
        XCTAssertEqual(states, [false, true])
    }

    func test_login_withWrongPassword_fails() {
        let auth = InMemoryAuthService()
        let result = auth.login(email: "test@sushi.ru", password: "wrong")
        if case .success = result { XCTFail("expected failure") }
        XCTAssertFalse(auth.isAuthenticated)
    }

    func test_register_createsUserAndAuthenticates() {
        let auth = InMemoryAuthService()
        let result = auth.register(name: "Баха", phone: "+79991234567",
                                   email: "new@sushi.ru", password: "secret1")
        if case .failure = result { XCTFail("expected success") }
        XCTAssertTrue(auth.isAuthenticated)
    }

    func test_register_withDuplicateEmail_returnsEmailTaken() {
        let auth = InMemoryAuthService()
        _ = auth.register(name: "A", phone: "1", email: "test@sushi.ru", password: "x")
        let result = auth.register(name: "B", phone: "2", email: "test@sushi.ru", password: "y")
        XCTAssertEqual(result, .failure(.emailTaken))
    }

    func test_logout_publishesUnauthenticated() {
        let auth = InMemoryAuthService()
        var states: [Bool] = []
        auth.isAuthenticatedPublisher.sink { states.append($0) }.store(in: &cancellables)
        _ = auth.login(email: "test@sushi.ru", password: "secret1")
        auth.logout()
        XCTAssertFalse(auth.isAuthenticated)
        XCTAssertEqual(states, [false, true, false])
    }
}
