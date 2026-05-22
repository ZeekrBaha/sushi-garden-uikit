import Foundation

final class ProfileViewModel {
    let profile: UserProfile?
    var onLogoutCompleted: (() -> Void)?

    private let auth: AuthServicing

    init(auth: AuthServicing) {
        self.auth = auth
        self.profile = auth.currentUser
    }

    func logout() {
        auth.logout()
        onLogoutCompleted?()
    }
}
