import AppIntents
import Foundation

// These intents live in the app process, with no separate extension or App Group.
@MainActor
final class CompletionPassStore {
    static let shared = CompletionPassStore()
    private let key = "mathgate.instagram.pass.v1"
    private let defaults = UserDefaults.standard

    private func update<T>(_ change: (inout CompletionPass) -> T) -> T {
        var pass = defaults.data(forKey: key)
            .flatMap { try? JSONDecoder().decode(CompletionPass.self, from: $0) } ?? CompletionPass()
        let result = change(&pass)
        if let data = try? JSONEncoder().encode(pass) { defaults.set(data, forKey: key) }
        return result
    }
    func beginRound() { update { $0.beginRound() } }
    func finishRound(timeExpired: Bool, score: Int, interrupted: Bool) {
        update { $0.finishRound(timeExpired: timeExpired, score: score, interrupted: interrupted) }
    }
    func checkAccess() -> Bool { update { $0.checkAccess() } }
    func appClosed() { update { $0.appClosed() } }
}

struct CheckInstagramAccess: AppIntent {
    static var title: LocalizedStringResource = "Check Instagram Access"
    static var description = IntentDescription("Returns Yes only after an uninterrupted MathGate round with at least one correct answer. Use in Instagram's Is Opened automation before deciding whether to open MathGate.")
    static var openAppWhenRun: Bool = false

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<Bool> {
        .result(value: CompletionPassStore.shared.checkAccess())
    }
}

struct EndInstagramVisit: AppIntent {
    static var title: LocalizedStringResource = "End Instagram Visit"
    static var description = IntentDescription("Clears the current Instagram visit. Use only in Instagram's Is Closed automation. Never grants access and never opens MathGate.")
    static var openAppWhenRun: Bool = false

    @MainActor
    func perform() async throws -> some IntentResult {
        CompletionPassStore.shared.appClosed()
        return .result()
    }
}
