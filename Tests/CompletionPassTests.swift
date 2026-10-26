import XCTest
@testable import MathGateCore

final class CompletionPassTests: XCTestCase {
    let start = Date(timeIntervalSince1970: 1_000_000)

    func testAccessExpiresExactlyOneHourAfterCompletionNotAfterLastOpen() {
        var pass = CompletionPass()
        XCTAssertFalse(pass.checkAccess(now: start))
        pass.finishRound(timeExpired: true, score: 3, interrupted: false, duration: 30, now: start)
        for seconds in [0.0, 10, 1800, 3599.999] {
            XCTAssertTrue(pass.checkAccess(now: start.addingTimeInterval(seconds)))
            pass.appClosed()
        }
        XCTAssertFalse(pass.checkAccess(now: start.addingTimeInterval(3600)))
        XCTAssertFalse(pass.checkAccess(now: start.addingTimeInterval(7200)))
        XCTAssertFalse(pass.checkAccess(now: start.addingTimeInterval(-1)))
    }
    func testShortIncompleteInterruptedOrZeroScoreRoundsCannotGrant() {
        for duration in [15.0, 30, 60] {
            for expired in [false, true] {
                for interrupted in [false, true] {
                    for score in [0, 1] {
                        var pass = CompletionPass()
                        pass.finishRound(timeExpired: expired, score: score, interrupted: interrupted,
                                         duration: duration, now: start)
                        XCTAssertEqual(pass.checkAccess(now: start), duration >= 30 && expired && !interrupted && score > 0)
                    }
                }
            }
        }
    }
    func testPersistenceAndLegacyPassMigration() throws {
        var pass = CompletionPass()
        pass.finishRound(timeExpired: true, score: 1, interrupted: false, duration: 60, now: start)
        let restored = try JSONDecoder().decode(CompletionPass.self, from: JSONEncoder().encode(pass))
        XCTAssertTrue(restored.checkAccess(now: start.addingTimeInterval(100)))
        XCTAssertFalse(restored.checkAccess(now: start.addingTimeInterval(3600)))
        for state in ["locked", "ready", "active"] {
            let data = Data("{\"state\":\"\(state)\"}".utf8)
            let legacy = try JSONDecoder().decode(CompletionPass.self, from: data)
            XCTAssertFalse(legacy.checkAccess(now: start))
        }
    }
    func testExtraPracticeDoesNotRevokeAccessOrExtendItWithoutCompletion() {
        var pass = CompletionPass()
        pass.finishRound(timeExpired: true, score: 2, interrupted: false, duration: 30, now: start)
        pass.beginRound()
        pass.finishRound(timeExpired: false, score: 3, interrupted: true, duration: 30,
                         now: start.addingTimeInterval(100))
        XCTAssertTrue(pass.checkAccess(now: start.addingTimeInterval(200)))
        XCTAssertFalse(pass.checkAccess(now: start.addingTimeInterval(3600)))
        pass.finishRound(timeExpired: true, score: 2, interrupted: false, duration: 30,
                         now: start.addingTimeInterval(3700))
        XCTAssertTrue(pass.checkAccess(now: start.addingTimeInterval(4000)))
        XCTAssertFalse(pass.checkAccess(now: start.addingTimeInterval(7300)))
    }
}
