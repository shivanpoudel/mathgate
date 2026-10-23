import Foundation

struct NumberRange: Codable, Equatable {
    var lower: Int
    var upper: Int
    var normalized: NumberRange {
        let low = min(max(lower, 1), 999)
        return NumberRange(lower: low, upper: min(max(upper, low), 999))
    }
    var values: ClosedRange<Int> { normalized.lower...normalized.upper }
}

struct MathConfiguration: Codable, Equatable {
    var questionCount = 10
    var disableQuestionCount: Int { normalized.questionCount + 5 }
    var operations = Set(Problem.Operation.allCases)
    var addition = NumberRange(lower: 2, upper: 100)
    var firstFactor = NumberRange(lower: 2, upper: 12)
    var secondFactor = NumberRange(lower: 2, upper: 100)
    init() {}
    private enum CodingKeys: String, CodingKey {
        case questionCount, operations, addition, firstFactor, secondFactor
    }
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        questionCount = try values.decodeIfPresent(Int.self, forKey: .questionCount) ?? 10
        operations = try values.decodeIfPresent(Set<Problem.Operation>.self, forKey: .operations) ?? Set(Problem.Operation.allCases)
        addition = try values.decodeIfPresent(NumberRange.self, forKey: .addition) ?? NumberRange(lower: 2, upper: 100)
        firstFactor = try values.decodeIfPresent(NumberRange.self, forKey: .firstFactor) ?? NumberRange(lower: 2, upper: 12)
        secondFactor = try values.decodeIfPresent(NumberRange.self, forKey: .secondFactor) ?? NumberRange(lower: 2, upper: 100)
    }
    var normalized: MathConfiguration {
        var result = self
        result.questionCount = min(max(questionCount, 1), 100)
        if result.operations.isEmpty { result.operations = Set(Problem.Operation.allCases) }
        result.addition = addition.normalized
        result.firstFactor = firstFactor.normalized
        result.secondFactor = secondFactor.normalized
        return result
    }
}

struct Problem: Equatable {
    let left: Int
    let right: Int
    let operation: Operation
    enum Operation: String, CaseIterable, Codable {
        case add = "+", subtract = "−", multiply = "×", divide = "÷"
        var title: String {
            switch self {
            case .add: return "Addition"
            case .subtract: return "Subtraction"
            case .multiply: return "Multiplication"
            case .divide: return "Division"
            }
        }
    }
    var answer: Int {
        switch operation {
        case .add: return left + right
        case .subtract: return left - right
        case .multiply: return left * right
        case .divide: return left / right
        }
    }
    var text: String { "\(left) \(operation.rawValue) \(right)" }
    static func random<R: RandomNumberGenerator>(
        configuration: MathConfiguration = MathConfiguration(), using rng: inout R
    ) -> Problem {
        let config = configuration.normalized
        // Stable ordering makes seeded test generators reproducible.
        let enabled = Operation.allCases.filter { config.operations.contains($0) }
        let op = enabled.randomElement(using: &rng)!
        switch op {
        case .add, .subtract:
            let a = Int.random(in: config.addition.values, using: &rng)
            let b = Int.random(in: config.addition.values, using: &rng)
            return op == .add ? Problem(left: a, right: b, operation: op)
                : Problem(left: a + b, right: a, operation: op)
        case .multiply, .divide:
            let a = Int.random(in: config.firstFactor.values, using: &rng)
            let b = Int.random(in: config.secondFactor.values, using: &rng)
            return op == .multiply ? Problem(left: a, right: b, operation: op)
                : Problem(left: a * b, right: a, operation: op)
        }
    }
}

struct Challenge {
    let questions: [Problem]
    private(set) var completed = 0
    var isComplete: Bool { completed == questions.count }
    var current: Problem? { isComplete ? nil : questions[completed] }
    init(configuration: MathConfiguration = MathConfiguration(), disablingBlocking: Bool = false) {
        var rng = SystemRandomNumberGenerator()
        var items: [Problem] = []
        let count = disablingBlocking ? configuration.disableQuestionCount : configuration.normalized.questionCount
        for _ in 0..<count {
            var item = Problem.random(configuration: configuration, using: &rng)
            // Bounded retries: a single possible problem must never hang the app.
            for _ in 0..<8 {
                guard items.last == item else { break }
                item = Problem.random(configuration: configuration, using: &rng)
            }
            items.append(item)
        }
        questions = items
    }
    init(questions: [Problem]) {
        precondition(!questions.isEmpty)
        self.questions = questions
    }
    @discardableResult mutating func submit(_ input: String) -> Bool {
        guard let current, let value = Int(input), value == current.answer else { return false }
        completed += 1
        return true
    }
}

// The caller supplies monotonic elapsed seconds so backgrounding cannot pause a round.
struct TimedPractice {
    let configuration: MathConfiguration
    let duration: TimeInterval
    private(set) var current: Problem
    private(set) var score = 0

    init(configuration: MathConfiguration, duration: TimeInterval) {
        self.configuration = configuration.normalized
        self.duration = duration.isFinite ? min(max(duration, 15), 300) : 60
        var rng = SystemRandomNumberGenerator()
        current = Problem.random(configuration: self.configuration, using: &rng)
    }
    func remaining(at elapsed: TimeInterval) -> TimeInterval {
        max(0, duration - max(0, elapsed))
    }
    @discardableResult mutating func submit(_ input: String, elapsed: TimeInterval) -> Bool {
        guard remaining(at: elapsed) > 0, Int(input) == current.answer else { return false }
        score += 1
        var rng = SystemRandomNumberGenerator()
        var next = Problem.random(configuration: configuration, using: &rng)
        for _ in 0..<8 {
            guard next == current else { break }
            next = Problem.random(configuration: configuration, using: &rng)
        }
        current = next
        return true
    }
}
