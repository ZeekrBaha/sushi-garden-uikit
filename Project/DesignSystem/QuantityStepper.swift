import UIKit

final class QuantityStepper: UIView {
    private(set) var count: Int = 1
    var onCountChanged: ((Int) -> Void)?

    private let decrementButton = UIButton(type: .system)
    private let countLabel = UILabel()
    private let incrementButton = UIButton(type: .system)

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func increment() {
        count += 1
        countLabel.text = "\(count)"
        onCountChanged?(count)
    }

    func decrement() {
        guard count > 1 else { return }
        count -= 1
        countLabel.text = "\(count)"
        onCountChanged?(count)
    }

    func setCount(_ newCount: Int) {
        guard newCount >= 1 else { return }
        count = newCount
        countLabel.text = "\(count)"
    }

    private func setup() {
        backgroundColor = AppColor.elevated
        layer.cornerRadius = Spacing.cardRadius
        translatesAutoresizingMaskIntoConstraints = false

        decrementButton.setTitle("−", for: .normal)
        decrementButton.setTitleColor(AppColor.textPrimary, for: .normal)
        decrementButton.titleLabel?.font = AppFont.price
        decrementButton.translatesAutoresizingMaskIntoConstraints = false
        decrementButton.addTarget(self, action: #selector(decrementTapped), for: .touchUpInside)

        countLabel.text = "\(count)"
        countLabel.textColor = AppColor.textPrimary
        countLabel.font = AppFont.weight
        countLabel.textAlignment = .center
        countLabel.translatesAutoresizingMaskIntoConstraints = false

        incrementButton.setTitle("+", for: .normal)
        incrementButton.setTitleColor(AppColor.textPrimary, for: .normal)
        incrementButton.titleLabel?.font = AppFont.price
        incrementButton.translatesAutoresizingMaskIntoConstraints = false
        incrementButton.addTarget(self, action: #selector(incrementTapped), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [decrementButton, countLabel, incrementButton])
        stack.axis = .horizontal
        stack.distribution = .equalSpacing
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 44),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Spacing.m),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Spacing.m),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }

    @objc private func decrementTapped() { decrement() }
    @objc private func incrementTapped() { increment() }
}
