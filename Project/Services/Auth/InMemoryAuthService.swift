import Foundation
import Combine

final class InMemoryAuthService: AuthServicing {
    private struct Account { let user: UserProfile; let password: String }

    private var accounts: [String: Account]
    private let authSubject = CurrentValueSubject<Bool, Never>(false)
    private(set) var currentUser: UserProfile?

    init() {
        let seeded = UserProfile(id: "seed", name: "Тест",
                                 phone: "+79990000000", email: "test@sushi.ru")
        accounts = ["test@sushi.ru": Account(user: seeded, password: "secret1")]
    }

    var isAuthenticated: Bool { authSubject.value }
    var isAuthenticatedPublisher: AnyPublisher<Bool, Never> { authSubject.eraseToAnyPublisher() }

    func login(email: String, password: String) -> Result<UserProfile, AuthError> {
        guard let account = accounts[email], account.password == password else {
            return .failure(.invalidCredentials)
        }
        currentUser = account.user
        authSubject.send(true)
        return .success(account.user)
    }

    func register(name: String, phone: String, email: String, password: String) -> Result<UserProfile, AuthError> {
        guard accounts[email] == nil else { return .failure(.emailTaken) }
        let user = UserProfile(id: UUID().uuidString, name: name, phone: phone, email: email)
        accounts[email] = Account(user: user, password: password)
        currentUser = user
        authSubject.send(true)
        return .success(user)
    }

    func logout() {
        currentUser = nil
        authSubject.send(false)
    }
}
