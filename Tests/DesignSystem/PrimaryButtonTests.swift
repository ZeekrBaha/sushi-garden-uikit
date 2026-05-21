import XCTest
@testable import SushiGarden

final class PrimaryButtonTests: XCTestCase {
    func test_backgroundColor_isAccent() {
        let sut = PrimaryButton()
        XCTAssertEqual(sut.backgroundColor, AppColor.accent)
    }

    func test_titleColor_isWhite() {
        let sut = PrimaryButton()
        XCTAssertEqual(sut.titleColor(for: .normal), UIColor.white)
    }

    func test_cornerRadius_isCardRadius() {
        let sut = PrimaryButton()
        XCTAssertEqual(sut.layer.cornerRadius, Spacing.cardRadius)
    }
}
