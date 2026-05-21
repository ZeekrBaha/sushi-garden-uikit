import Foundation
import Combine

enum AuthError: Error, Equatable {
    case invalidCredentials
    case emailTaken
}

protocol AuthServicing {
    var isAuthenticated: Bool { get }
    var isAuthenticatedPublisher: AnyPublisher<Bool, Never> { get }
    var currentUser: UserProfile? { get }
    func login(email: String, password: String) -> Result<UserProfile, AuthError>
    func register(name: String, phone: String, email: String, password: String) -> Result<UserProfile, AuthError>
    func logout()
}
