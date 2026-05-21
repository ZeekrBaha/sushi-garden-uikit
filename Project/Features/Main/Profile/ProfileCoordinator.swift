import UIKit

final class ProfileCoordinator: Coordinator {
    var childCoordinators: [Coordinator] = []

    let navigationController: UINavigationController
    private let container: AppContainer
    private let onLogout: () -> Void

    init(navigationController: UINavigationController = UINavigationController(),
         container: AppContainer,
         onLogout: @escaping () -> Void) {
        self.navigationController = navigationController
        self.container = container
        self.onLogout = onLogout
    }

    func start() {
        let vm = ProfileViewModel(auth: container.auth)
        vm.onLogoutCompleted = { [weak self] in self?.onLogout() }
        let vc = ProfileViewController(viewModel: vm)
        navigationController.setViewControllers([vc], animated: false)
    }
}
