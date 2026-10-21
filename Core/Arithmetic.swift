import Foundation

struct Problem: Equatable {
    let left: Int
    let right: Int
    let operation: Operation
    enum Operation: String, CaseIterable { case add = "+", subtract = "−", multiply = "×", divide = "÷" }
    var answer: Int {
        switch operation {
        case .add: return left + right
        case .subtract: return left - right
        case .multiply: return left * right
        case .divide: return left / right
        }
    }
    var text: String { "\(left) \(operation.rawValue) \(right)" }
    static func random<R: RandomNumberGenerator>(using rng: inout R) -> Problem {
        let op = Operation.allCases.randomElement(using: &rng)!
        switch op {
        case .add, .subtract:
            let a = Int.random(in: 2...100, using: &rng)
            let b = Int.random(in: 2...100, using: &rng)
            return op == .add ? Problem(left: a, right: b, operation: op)
                : Problem(left: a + b, right: a, operation: op)
        case .multiply, .divide:
            let a = Int.random(in: 2...12, using: &rng)
            let b = Int.random(in: 2...100, using: &rng)
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
    init() {
        var rng = SystemRandomNumberGenerator()
        var items: [Problem] = []
        while items.count < 10 {
            let item = Problem.random(using: &rng)
            if items.last != item { items.append(item) }
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
