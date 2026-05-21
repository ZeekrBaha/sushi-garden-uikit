import XCTest
@testable import SushiGarden

final class QuantityStepperTests: XCTestCase {
    func test_initialCount_isOne() {
        let sut = QuantityStepper()
        XCTAssertEqual(sut.count, 1)
    }

    func test_increment_increasesCount() {
        let sut = QuantityStepper()
        sut.increment()
        XCTAssertEqual(sut.count, 2)
    }

    func test_decrement_decreasesCount() {
        let sut = QuantityStepper()
        sut.increment()
        sut.decrement()
        XCTAssertEqual(sut.count, 1)
    }

    func test_decrement_atOne_doesNothing() {
        let sut = QuantityStepper()
        sut.decrement()
        XCTAssertEqual(sut.count, 1)
    }

    func test_onCountChanged_calledOnIncrement() {
        let sut = QuantityStepper()
        var received: Int?
        sut.onCountChanged = { received = $0 }
        sut.increment()
        XCTAssertEqual(received, 2)
    }

    func test_onCountChanged_calledOnDecrement() {
        let sut = QuantityStepper()
        sut.increment() // count = 2
        var received: Int?
        sut.onCountChanged = { received = $0 }
        sut.decrement()
        XCTAssertEqual(received, 1)
    }
}
