import UIKit

final class SplashViewController: UIViewController {
    var onContinue: (() -> Void)?
    private let splashDelay: TimeInterval

    init(splashDelay: TimeInterval = 1.5) {
        self.splashDelay = splashDelay
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppColor.background

        let label = UILabel()
        label.text = "SUSHI GARDEN"
        label.textColor = AppColor.textPrimary
        label.font = AppFont.price
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        view.accessibilityIdentifier = "splash.view"
        #if DEBUG
        if CommandLine.arguments.contains("--uitesting") {
            onContinue?()
            return
        }
        #endif
        DispatchQueue.main.asyncAfter(deadline: .now() + splashDelay) { [weak self] in
            self?.onContinue?()
        }
    }
}
