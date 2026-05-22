import UIKit

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    private var appCoordinator: AppCoordinator?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }
        FontLoader.registerCustomFonts()
        let window = UIWindow(windowScene: windowScene)
        let container = AppContainer()
        #if DEBUG
        if CommandLine.arguments.contains("--uitesting-authenticated") {
            _ = container.auth.login(email: "test@sushi.ru", password: "secret1")
        }
        #endif
        let coordinator = AppCoordinator(window: window, container: container)
        self.window = window
        self.appCoordinator = coordinator
        coordinator.start()
    }
}
