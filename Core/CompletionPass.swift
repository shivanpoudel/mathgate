import Foundation

/// A fixed one-hour window starting when a qualifying round finishes.
struct CompletionPass: Codable, Equatable {
    private(set) var grantedAt: Date?
    private(set) var expiresAt: Date?

    // Extra practice must not revoke or extend an already-earned window.
    mutating func beginRound() {}
    mutating func finishRound(timeExpired: Bool, score: Int, interrupted: Bool,
                              duration: TimeInterval, now: Date = Date()) {
        guard timeExpired, score > 0, !interrupted, duration.isFinite, duration >= 30 else { return }
        grantedAt = now
        expiresAt = now.addingTimeInterval(60 * 60)
    }
    func checkAccess(now: Date = Date()) -> Bool {
        guard let grantedAt, let expiresAt else { return false }
        return now >= grantedAt && now < expiresAt
    }
    // Retained for existing Is Closed automations. Leaving Instagram no longer resets access.
    mutating func appClosed() {}
}
