import UIKit

enum AppFont {
    static func sen(_ size: CGFloat, weight: UIFont.Weight = .regular) -> UIFont {
        let name = weight == .bold ? "Sen-Bold" : "Sen-Regular"
        return UIFont(name: name, size: size) ?? .systemFont(ofSize: size, weight: weight)
    }

    // Semantic styles from the Figma.
    static var price: UIFont { sen(19, weight: .bold) }
    static var productTitle: UIFont { sen(16.5, weight: .bold) }
    static var categoryTab: UIFont { sen(15.8, weight: .bold) }
    static var weight: UIFont { sen(14) }
    static var caption: UIFont { sen(12) }
    static var tabLabel: UIFont { sen(11.8) }
}
