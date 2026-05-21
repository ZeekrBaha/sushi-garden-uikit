import UIKit

final class AuthCoordinator: Coordinator {
    var childCoordinators: [Coordinator] = []

    let navigationController: UINavigationController
    private let container: AppContainer

    init(navigationController: UINavigationController = UINavigationController(),
         container: AppContainer) {
        self.navigationController = navigationController
        self.container = container
    }

    func start() {
        let vc = SplashViewController()
        vc.onContinue = { [weak self] in self?.showLogin() }
        navigationController.setViewControllers([vc], animated: false)
    }

    private func showLogin() {
        let vm = LoginViewModel(auth: container.auth)
        vm.onGoToRegister = { [weak self] in self?.showRegister() }
        let vc = LoginViewController(viewModel: vm)
        navigationController.setViewControllers([vc], animated: false)
    }

    private func showRegister() {
        let vm = RegisterViewModel(auth: container.auth)
        vm.onGoToLogin = { [weak self] in self?.showLogin() }
        let vc = RegisterViewController(viewModel: vm)
        navigationController.setViewControllers([vc], animated: false)
    }
}
