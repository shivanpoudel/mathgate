import XCTest
@testable import MathGateCore

final class ArithmeticTests: XCTestCase {
    func testWrongAndEmptyAnswersDoNotAdvance() {
        var challenge = Challenge(questions: [.init(left: 12, right: 7, operation: .multiply)])
        for input in ["", "8", "85", "eight", "84.0"] {
            XCTAssertFalse(challenge.submit(input))
            XCTAssertEqual(challenge.completed, 0)
        }
        XCTAssertTrue(challenge.submit("84"))
        XCTAssertTrue(challenge.isComplete)
        XCTAssertFalse(challenge.submit("84"))
        XCTAssertEqual(challenge.completed, 1)
    }
    func testExactlyTenCorrectAnswersAreRequired() {
        var challenge = Challenge()
        for i in 0..<10 {
            XCTAssertEqual(challenge.completed, i)
            XCTAssertFalse(challenge.isComplete)
            XCTAssertTrue(challenge.submit(String(challenge.current!.answer)))
        }
        XCTAssertTrue(challenge.isComplete)
        XCTAssertNil(challenge.current)
    }
    func testGeneratedDivisionIsIntegralAndSubtractionNonnegative() {
        var rng = SystemRandomNumberGenerator()
        for _ in 0..<10000 {
            let p = Problem.random(using: &rng)
            XCTAssertGreaterThan(p.answer, 0)
            if p.operation == .divide {
                XCTAssertNotEqual(p.right, 0)
                XCTAssertEqual(p.left % p.right, 0)
                XCTAssertEqual(p.answer * p.right, p.left)
            }
            if p.operation == .subtract { XCTAssertEqual(p.answer + p.right, p.left) }
        }
    }
}
