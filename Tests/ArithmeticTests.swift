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


private struct SeededGenerator: RandomNumberGenerator {
    var state: UInt64 = 42
    mutating func next() -> UInt64 {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return state
    }
}

final class MathConfigurationTests: XCTestCase {
    func testOnlySelectedOperationAndConfiguredRangesAreUsed() {
        for operation in Problem.Operation.allCases {
            var config = MathConfiguration()
            config.operations = [operation]
            config.addition = NumberRange(lower: 7, upper: 9)
            config.firstFactor = NumberRange(lower: 3, upper: 5)
            config.secondFactor = NumberRange(lower: 11, upper: 13)
            var rng = SeededGenerator()
            for _ in 0..<200 {
                let p = Problem.random(configuration: config, using: &rng)
                XCTAssertEqual(p.operation, operation)
                switch operation {
                case .add:
                    XCTAssertTrue((7...9).contains(p.left))
                    XCTAssertTrue((7...9).contains(p.right))
                case .subtract:
                    XCTAssertTrue((7...9).contains(p.right))
                    XCTAssertTrue((7...9).contains(p.answer))
                case .multiply:
                    XCTAssertTrue((3...5).contains(p.left))
                    XCTAssertTrue((11...13).contains(p.right))
                case .divide:
                    XCTAssertTrue((3...5).contains(p.right))
                    XCTAssertTrue((11...13).contains(p.answer))
                    XCTAssertEqual(p.left % p.right, 0)
                }
            }
        }
    }
    func testSinglePossibleQuestionStillProducesTenQuestions() {
        var config = MathConfiguration()
        config.operations = [.multiply]
        config.firstFactor = NumberRange(lower: 1, upper: 1)
        config.secondFactor = NumberRange(lower: 1, upper: 1)
        let challenge = Challenge(configuration: config)
        XCTAssertEqual(challenge.questions.count, 10)
        XCTAssertTrue(challenge.questions.allSatisfy { $0.answer == 1 })
    }
    func testInvalidStoredConfigurationIsNormalized() {
        var config = MathConfiguration()
        config.operations = []
        config.addition = NumberRange(lower: -10, upper: -30)
        config.firstFactor = NumberRange(lower: 9000, upper: 0)
        config.secondFactor = NumberRange(lower: 2, upper: Int.max)
        let normalized = config.normalized
        XCTAssertEqual(normalized.operations.count, 4)
        XCTAssertEqual(normalized.addition, NumberRange(lower: 1, upper: 1))
        XCTAssertEqual(normalized.firstFactor, NumberRange(lower: 999, upper: 999))
        XCTAssertEqual(normalized.secondFactor.upper, 999)
        var rng = SeededGenerator()
        for _ in 0..<100 {
            XCTAssertGreaterThan(Problem.random(configuration: config, using: &rng).answer, 0)
        }
    }
    func testConfigurationRoundTripsThroughPersistence() throws {
        var config = MathConfiguration()
        config.operations = [.divide, .subtract]
        config.addition = NumberRange(lower: 20, upper: 40)
        let data = try JSONEncoder().encode(config)
        XCTAssertEqual(try JSONDecoder().decode(MathConfiguration.self, from: data), config)
    }
    func testChangingSettingsDoesNotModifyAnExistingRound() {
        var config = MathConfiguration()
        config.operations = [.add]
        let challenge = Challenge(configuration: config)
        config.operations = [.divide]
        XCTAssertTrue(challenge.questions.allSatisfy { $0.operation == .add })
        XCTAssertTrue(Challenge(configuration: config).questions.allSatisfy { $0.operation == .divide })
    }
}

final class GateCountTests: XCTestCase {
    func testCustomCountAndExtraQuestionsMustAllBeCompleted() {
        for count in [1, 10, 23, 100] {
            var config = MathConfiguration()
            config.questionCount = count
            for disabling in [false, true] {
                var challenge = Challenge(configuration: config, disablingBlocking: disabling)
                let expected = count + (disabling ? 5 : 0)
                XCTAssertEqual(challenge.questions.count, expected)
                for _ in 0..<expected {
                    XCTAssertFalse(challenge.isComplete)
                    XCTAssertFalse(challenge.submit("incorrect"))
                    XCTAssertTrue(challenge.submit(String(challenge.current!.answer)))
                }
                XCTAssertTrue(challenge.isComplete)
                XCTAssertNil(challenge.current)
            }
        }
    }
    func testLegacyPreferencesKeepMathChoicesAndDefaultToTen() throws {
        let json = #"{"operations":["+"],"addition":{"lower":7,"upper":9},"firstFactor":{"lower":3,"upper":4},"secondFactor":{"lower":5,"upper":6}}"#
        let config = try JSONDecoder().decode(MathConfiguration.self, from: Data(json.utf8))
        XCTAssertEqual(config.questionCount, 10)
        XCTAssertEqual(config.disableQuestionCount, 15)
        XCTAssertEqual(config.operations, [.add])
        XCTAssertEqual(config.addition, NumberRange(lower: 7, upper: 9))
        XCTAssertEqual(config.firstFactor, NumberRange(lower: 3, upper: 4))
        XCTAssertEqual(config.secondFactor, NumberRange(lower: 5, upper: 6))
    }
    func testCountsAreBoundedAndPersist() throws {
        var config = MathConfiguration()
        config.questionCount = Int.min
        XCTAssertEqual(Challenge(configuration: config).questions.count, 1)
        config.questionCount = Int.max
        XCTAssertEqual(Challenge(configuration: config, disablingBlocking: true).questions.count, 105)
        config.questionCount = 27
        let data = try JSONEncoder().encode(config)
        XCTAssertEqual(try JSONDecoder().decode(MathConfiguration.self, from: data).questionCount, 27)
        let challenge = Challenge(configuration: config)
        config.questionCount = 3
        XCTAssertEqual(challenge.questions.count, 27)
    }
}
