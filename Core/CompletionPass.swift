import Foundation

/// One earned visit. A close during the redirect must not erase an unused pass.
struct CompletionPass: Codable, Equatable {
    enum State: String, Codable { case locked, ready, active }
    private(set) var state: State = .locked

    mutating func beginRound() { state = .locked }
    mutating func finishRound(timeExpired: Bool, score: Int, interrupted: Bool) {
        state = timeExpired && score > 0 && !interrupted ? .ready : .locked
    }
    mutating func checkAccess() -> Bool {
        guard state != .locked else { return false }
        state = .active
        return true
    }
    mutating func appClosed() {
        if state == .active { state = .locked }
    }
}
