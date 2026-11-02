import XCTest
@testable import BalloonBaronCore

/// v132 (TestFlight): a booked Balloon Show is never lost without a word, and the holding's €1 million goal is met the
/// moment the cash reaches it and stays met.
final class TesterFixes132Tests: XCTestCase {
    func showGame(balloons: Int = 8, seed: UInt64 = 3) -> Game {
        var g = Game(company: "Test Air", colors: Rules.palettes[0], seed: seed)
        g.state.tutorial = TutorialState(done: true)
        g.state.day = 30
        g.state.lastSelfFly = 30
        g.state.cash = 500_000
        g.state.unlocked.insert(.market)
        g.state.buildings = [.hangar: 2]
        for i in 1..<balloons { g.state.balloons.append(Balloon(id: 700 + i, size: .M, name: "B\(i)")) }
        for i in 0..<balloons { g.state.pilots.append(Pilot(id: 800 + i, name: "P \(i)", level: .experienced)) }
        g.startDay()
        return g
    }

    func isShow(_ e: NightEvent?) -> Bool { if case .show? = e { return true }; return false }

    /// The tester's night: a red-flag day flown anyway (a fine, an antitrust fine, the bank taking a balloon). Over many
    /// days either the show plays that night, or the report says it was called off and every fee came back.
    func testABookedShowPlaysOrIsCalledOffOutLoud() {
        var played = 0, off = 0
        for seed in 1...240 as ClosedRange<UInt64> {
            var g = showGame(seed: seed)
            XCTAssertTrue(g.bookShow())
            if seed % 2 == 0 { g.state.weather?.flag = .red }
            if seed % 5 == 0 { g.state.monopolyDays = 9 }
            if seed % 7 == 0 { g.state.cash = -20_000 }
            let paid = 8 * Rules.showPerBalloon
            g.launch(skip: false)
            let r = g.finishDay(flight: nil)
            let night = g.startNight()
            if r.events.contains(where: { if case .showCancelled = $0 { true } else { false } }) {
                off += 1
                XCTAssertFalse(isShow(night), "seed \(seed)")
                XCTAssertEqual(r.ledger.showRefund, paid, "seed \(seed): every fee came back")
                XCTAssertEqual(g.showState == .ok || g.showState == .few || g.showState == .cash, true, "a new one can be booked")
            } else {
                played += 1
                XCTAssertTrue(isShow(night), "seed \(seed): \(r.events)")
                XCTAssertTrue(r.events.contains(where: { if case .showTonight = $0 { true } else { false } }))
            }
        }
        XCTAssertGreaterThan(played, 0)
        XCTAssertGreaterThan(off, 0, "red-flag days with many accidents call some shows off")
    }

    /// The bank takes a balloon that was in the show: it drops out and its fee comes back, the rest still play.
    func testSeizedBalloonDropsOutOfTheShow() {
        var g = showGame(balloons: 7)
        XCTAssertTrue(g.bookShow())
        g.launch(skip: true)
        g.state.cash = -50_000
        let r = g.finishDay(flight: nil)
        XCTAssertTrue(r.events.contains(.showSeized(refund: Rules.showPerBalloon)), "\(r.events)")
        let ids = g.state.local.showIDs ?? []
        XCTAssertEqual(ids.count, 6)
        XCTAssertTrue(ids.allSatisfy { g.state.balloon($0) != nil })
        XCTAssertTrue(isShow(g.startNight()))
    }

    /// Leaving the region on the show's day: it's called off, the fee goes back to that region's box and the guide says so.
    func testLeavingOnShowDayRefunds() throws {
        var g = showGame()
        g.state.chapter = 4
        g.state.barons[.cap] = 1
        g.grantStoreItem(.worldTour)
        g.state.holding.cash = 200_000
        XCTAssertTrue(g.bookShow())
        let cash = g.state.cash
        XCTAssertTrue(g.enterRegion(.abq))
        let cap = try XCTUnwrap(g.state.parked[.cap]).state
        XCTAssertEqual(cap.cash, cash + 8 * Rules.showPerBalloon)
        XCTAssertNil(cap.showTonight)
        XCTAssertNil(cap.showNext, "it can be booked again on coming back")
        XCTAssertTrue(g.state.hezQueue.contains(.nightCalledOff(.cap, show: true, refund: 8 * Rules.showPerBalloon)))
    }

    /// A Night Glow booked for tonight keeps the night: the show waits.
    func testShowWaitsForABookedGlow() {
        var g = showGame()
        g.state.local.glowTonight = g.state.day
        XCTAssertEqual(g.showState, .glow)
        XCTAssertFalse(g.bookShow())
    }

    // MARK: Holding €1 million

    func baronGame() -> Game {
        var g = Game(company: "Test Air", colors: Rules.palettes[0], seed: 42)
        g.state.tutorial = TutorialState(done: true)
        g.startDay()
        g.state.chapter = 4
        g.state.barons[.cap] = 1
        g.grantStoreItem(.worldTour)
        return g
    }

    /// The tester: 1,000,700 in the holding, then an office bought: 650,700. The goal stays ticked.
    func testMillionIsMetTheMomentItIsReachedAndStays() {
        var g = baronGame()
        g.state.holding.cash = 990_000
        g.state.cash = 20_700
        XCTAssertFalse(g.state.done(.million))
        g.withdraw(share: 1) // 10,700 to the holding by hand
        XCTAssertEqual(g.state.holding.cash, 1_000_700)
        XCTAssertEqual(g.state.holding.millionOn, g.state.day, "met at once, not at the end of the day")
        XCTAssertTrue(g.openOffice(.ist))
        XCTAssertLessThan(g.state.holding.cash, Holding.millionGoal)
        XCTAssertTrue(g.state.done(.million), "spending the money later doesn't untick it")
    }

    func testMillionFromAutopilotIncomeAndOldSaves() throws {
        var g = baronGame()
        // a parked region's income reaching the holding at the end of the day
        g.state.local.netHistory = [20000, 22000, 24000]
        g.state.holding.cash = 300_000
        XCTAssertTrue(g.enterRegion(.abq))
        g.state.holding.cash = 999_999
        g.runAutopilots()
        _ = g.holdingDay()
        XCTAssertGreaterThanOrEqual(g.state.holding.cash, Holding.millionGoal)
        XCTAssertNotNil(g.state.holding.millionOn)
        // an old save with no `millionOn` decodes; a cash box over a million counts at once
        var json = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(g.state.holding)) as? [String: Any])
        json.removeValue(forKey: "millionOn")
        let back = try JSONDecoder().decode(Holding.self, from: JSONSerialization.data(withJSONObject: json))
        XCTAssertNil(back.millionOn)
    }

    /// The brought balloons' daily payment is logged, so the whiteboard line worked back from today matches the cash.
    func testTransferPaymentIsLogged() {
        var g = baronGame()
        g.state.local.transferDebt = TransferDebt(left: 3, installment: 5000, from: .cap)
        var lg = Ledger()
        g.transferPay(&lg)
        XCTAssertEqual(g.state.holding.history.last?.income, 5000)
    }
}
