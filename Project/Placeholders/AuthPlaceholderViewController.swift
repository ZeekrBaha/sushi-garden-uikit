import UIKit

final class AuthPlaceholderViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppColor.background
        let label = UILabel()
        label.text = "Auth (Phase 2)"
        label.textColor = AppColor.textPrimary
        label.font = AppFont.productTitle
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }
}
