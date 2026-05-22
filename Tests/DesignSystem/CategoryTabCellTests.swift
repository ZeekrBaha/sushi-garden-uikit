import XCTest
@testable import SushiGarden

final class CategoryTabCellTests: XCTestCase {
    func test_configure_setsTitle() {
        let sut = CategoryTabCell()
        sut.configure(name: "Роллы", isSelected: false)
        XCTAssertEqual(sut.titleLabel.text, "Роллы")
    }

    func test_configure_selected_usesAccentBackground() {
        let sut = CategoryTabCell()
        sut.configure(name: "Роллы", isSelected: true)
        XCTAssertEqual(sut.contentView.backgroundColor, AppColor.accent)
    }

    func test_configure_unselected_usesElevatedBackground() {
        let sut = CategoryTabCell()
        sut.configure(name: "Роллы", isSelected: false)
        XCTAssertEqual(sut.contentView.backgroundColor, AppColor.elevated)
    }
}
