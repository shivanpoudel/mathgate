import XCTest
@testable import MathGateCore

final class CompletionPassTests: XCTestCase {
    func testIncompleteRoundAndRepeatedReentryStayLocked() {
        var pass = CompletionPass()
        XCTAssertFalse(pass.checkAccess())
        pass.appClosed()
        pass.beginRound()
        pass.finishRound(timeExpired: false, score: 10, interrupted: false)
        XCTAssertFalse(pass.checkAccess())
        pass.appClosed()
        XCTAssertFalse(pass.checkAccess())
    }
    func testOnlyCompletedForegroundRoundEarnsVisit() {
        for interrupted in [false, true] {
            for score in [0, 1, 10] {
                var pass = CompletionPass()
                pass.finishRound(timeExpired: true, score: score, interrupted: interrupted)
                XCTAssertEqual(pass.checkAccess(), !interrupted && score > 0)
            }
        }
    }
    func testRedirectCloseDoesNotConsumeReadyPassButLeavingVisitDoes() throws {
        var pass = CompletionPass()
        pass.finishRound(timeExpired: true, score: 3, interrupted: false)
        pass.appClosed()
        let data = try JSONEncoder().encode(pass)
        pass = try JSONDecoder().decode(CompletionPass.self, from: data)
        XCTAssertTrue(pass.checkAccess())
        XCTAssertTrue(pass.checkAccess()) // A repeated open check does not create a redirect loop.
        pass.appClosed()
        XCTAssertFalse(pass.checkAccess())
    }
    func testRetryCannotReuseEarlierPass() {
        var pass = CompletionPass()
        pass.finishRound(timeExpired: true, score: 3, interrupted: false)
        pass.beginRound()
        XCTAssertFalse(pass.checkAccess())
    }
}
