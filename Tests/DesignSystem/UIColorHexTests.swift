import XCTest
@testable import SushiGarden

final class UIColorHexTests: XCTestCase {
    func test_hexInitializer_parsesAccentRed() {
        let color = UIColor(hex: 0xEC1A35)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        XCTAssertEqual(r, 0xEC / 255, accuracy: 0.001)
        XCTAssertEqual(g, 0x1A / 255, accuracy: 0.001)
        XCTAssertEqual(b, 0x35 / 255, accuracy: 0.001)
        XCTAssertEqual(a, 1.0, accuracy: 0.001)
    }
}
