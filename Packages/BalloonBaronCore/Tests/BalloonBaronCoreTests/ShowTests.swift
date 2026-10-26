import XCTest
@testable import BalloonBaronCore

/// v111: the Balloon Show.
final class ShowTests: XCTestCase {
    func showGame(balloons: Int = 8, seed: UInt64 = 3) -> Game {
        var g = Game(company: "Test Air", colors: Rules.palettes[0], seed: seed)
        g.state.day = 30
        g.state.lastSelfFly = 30
        g.state.cash = 500_000
        g.state.unlocked.insert(.market)
        for i in 1..<balloons { g.state.balloons.append(Balloon(id: 700 + i, size: .M, name: "B\(i)")) }
        for i in 0..<balloons { g.state.pilots.append(Pilot(id: 800 + i, name: "P \(i)", level: .experienced)) }
        g.startDay()
        return g
    }

    func testCostRulesAndCooldown() {
        var g = showGame()
        XCTAssertEqual(g.showState, .ok)
        XCTAssertEqual(g.showCost, 8 * Rules.showPerBalloon)
        g.state.balloons[2].damagedUntil = g.state.day + 2
        XCTAssertEqual(g.showCost, 7 * Rules.showPerBalloon, "a balloon in repair stays out and isn't paid for")
        let cash = g.state.cash
        XCTAssertTrue(g.bookShow())
        XCTAssertEqual(g.state.cash, cash - 7 * Rules.showPerBalloon)
        XCTAssertEqual(g.showState, .booked)
        XCTAssertFalse(g.bookShow())
        g.state.day += 1
        XCTAssertEqual(g.showState, .wait(days: Rules.showCooldown - 1))
        g.state.day += Rules.showCooldown - 1
        XCTAssertEqual(g.showState, .ok)
        var few = showGame(balloons: 4)
        XCTAssertEqual(few.showState, .few)
        XCTAssertFalse(few.bookShow())
        var poor = showGame()
        poor.state.cash = 1000
        XCTAssertEqual(poor.showState, .cash)
        var early = showGame()
        early.state.unlocked.remove(.market)
        XCTAssertEqual(early.showState, .locked)
    }

    func testEffectsNightAndTourists() {
        var g = showGame()
        let rep0 = g.state.rep
        XCTAssertTrue(g.bookShow())
        g.launch(skip: true)
        let r = g.finishDay(flight: nil)
        XCTAssertTrue(r.events.contains(.showTonight(balloons: 8)))
        XCTAssertGreaterThan(g.state.rep, rep0 + Rules.showRep * 0.5)
        XCTAssertTrue(g.state.paperNext?.contains(.show(balloons: 8)) ?? false)
        XCTAssertEqual(g.startNight(), .show(balloons: g.state.local.showIDs ?? []))
        // Show tourists come for the next three days, then stop.
        for d in 0..<4 {
            g.startDay()
            let has = g.referralSources().contains { $0.source == .show }
            XCTAssertEqual(has, d < Rules.showDays, "day \(d + 1) after the show")
            g.launch(skip: true)
            _ = g.finishDay(flight: nil)
        }
        XCTAssertNotEqual(g.startNight(), .show(balloons: g.state.local.showIDs ?? []), "only the one night")
    }

    func testOldSaveDecodes() throws {
        let g = showGame()
        var json = try JSONSerialization.jsonObject(with: JSONEncoder().encode(g.state.local)) as! [String: Any]
        for k in ["showTonight", "showIDs", "showNext", "showUntil", "lastShow", "showCount"] { json.removeValue(forKey: k) }
        let back = try JSONDecoder().decode(RegionState.self, from: JSONSerialization.data(withJSONObject: json))
        XCTAssertNil(back.showTonight)
    }

    /// v111.1: a balloon that crashes on show day drops out and its fee comes back; below the minimum the show is off.
    func testCrashesOnShowDay() {
        var g = showGame(balloons: 7)
        XCTAssertTrue(g.bookShow())
        g.launch(skip: true)
        g.state.balloons[1].damagedUntil = g.state.day + 3
        let r = g.finishDay(flight: nil)
        XCTAssertTrue(r.events.contains(.showDropped(refund: Rules.showPerBalloon)))
        XCTAssertTrue(r.events.contains(.showTonight(balloons: 6)))

        var h = showGame(balloons: 5)
        XCTAssertTrue(h.bookShow())
        let paid = h.state.cash
        h.launch(skip: true)
        h.state.balloons[2].damagedUntil = h.state.day + 3
        let r2 = h.finishDay(flight: nil)
        XCTAssertTrue(r2.events.contains(.showCancelled(refund: 4 * Rules.showPerBalloon)))
        XCTAssertFalse(r2.events.contains(where: { if case .showTonight = $0 { true } else { false } }))
        XCTAssertNil(h.startNight().flatMap { if case .show = $0 { $0 } else { nil } }, "no show tonight")
        XCTAssertGreaterThan(h.state.cash, paid, "every fee came back")
        h.startDay()
        XCTAssertEqual(h.showState, .few, "four can fly until the repair is done; then it can be booked again at once")
        h.state.balloons[2].damagedUntil = 0
        XCTAssertEqual(h.showState, .ok)
    }
}
