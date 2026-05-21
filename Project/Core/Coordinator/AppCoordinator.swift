import UIKit
import Combine

final class AppCoordinator: Coordinator {
    var childCoordinators: [Coordinator] = []

    private let window: UIWindow
    private let container: AppContainer
    private var cancellables = Set<AnyCancellable>()

    init(window: UIWindow, container: AppContainer) {
        self.window = window
        self.container = container
    }

    func start() {
        container.auth.isAuthenticatedPublisher
            .removeDuplicates()
            .sink { [weak self] isAuthenticated in
                self?.setRoot(isAuthenticated: isAuthenticated)
            }
            .store(in: &cancellables)
        window.makeKeyAndVisible()
    }

    private func setRoot(isAuthenticated: Bool) {
        if isAuthenticated {
            childCoordinators.removeAll()
            window.rootViewController = MainPlaceholderViewController()
        } else {
            let nav = UINavigationController()
            nav.navigationBar.isHidden = true
            let authCoordinator = AuthCoordinator(navigationController: nav, container: container)
            addChild(authCoordinator)
            authCoordinator.start()
            window.rootViewController = nav
        }
    }
}
