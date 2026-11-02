import XCTest
@testable import BalloonBaronCore

/// v133: the flagship's three-day grace, the holding's rescue (once per region, at a heavy price) and a region closing
/// instead of the whole game when you own a holding.
final class Bankruptcy133Tests: XCTestCase {
    /// A company down to its flagship, cash far below the bank's line.
    func broke(seed: UInt64 = 5, balloons: Int = 1) -> Game {
        var g = Game(company: "Test Air", colors: Rules.palettes[0], seed: seed)
        g.state.tutorial = TutorialState(done: true)
        g.state.day = 60
        g.state.lastSelfFly = 60
        for i in 1..<balloons { g.state.balloons.append(Balloon(id: 500 + i, size: .M, name: "B\(i)")) }
        g.startDay()
        return g
    }

    /// Ends a day (no flight) with cash set to `cash` just before the close.
    @discardableResult
    func close(_ g: inout Game, cash: Int) -> DayReport {
        g.launch(skip: true)
        g.state.cash = cash
        let r = g.finishDay(flight: nil)
        if !g.state.over && g.state.ruinPending == nil {
            _ = g.startNight()
            g.startDay()
        }
        return r
    }

    /// A holding with a second region (Albuquerque), playing there.
    func withHolding(holding: Int) -> Game {
        var g = broke()
        g.state.chapter = 4
        g.state.barons[.cap] = 50
        g.grantStoreItem(.worldTour)
        for i in 1...5 { g.state.balloons.append(Balloon(id: 600 + i, size: .M, name: "C\(i)")) }
        g.state.holding.cash = 100_000
        XCTAssertTrue(g.enterRegion(.abq))
        g.state.holding.cash = holding
        return g
    }

    func testFlagshipSurvivesTwoBadDaysAndGoesOnTheThird() {
        var g = broke()
        let r1 = close(&g, cash: -20_000)
        XCTAssertEqual(g.state.balloons.count, 1)
        XCTAssertEqual(g.state.local.debtDays, 1)
        XCTAssertTrue(r1.events.contains(.flagshipGrace(daysLeft: 2)), "\(r1.events)")
        XCTAssertTrue(g.rescueDue, "the rescue plan opens on the first such morning")
        let r2 = close(&g, cash: -20_000)
        XCTAssertEqual(g.state.balloons.count, 1)
        XCTAssertTrue(r2.events.contains(.flagshipGrace(daysLeft: 1)))
        XCTAssertFalse(g.state.over)
        close(&g, cash: -20_000)
        XCTAssertTrue(g.state.balloons.isEmpty)
        XCTAssertTrue(g.state.over, "no holding: the game ends as before")
        XCTAssertNil(g.state.ruinPending)
    }

    func testCounterResetsWhenCashRecovers() {
        var g = broke()
        close(&g, cash: -20_000)
        close(&g, cash: -20_000)
        XCTAssertEqual(g.state.local.debtDays, 2)
        close(&g, cash: 1_000)
        XCTAssertNil(g.state.local.debtDays)
        close(&g, cash: -20_000)
        close(&g, cash: -20_000)
        XCTAssertEqual(g.state.balloons.count, 1, "two bad days after a good one: still flying")
        XCTAssertFalse(g.state.over)
    }

    func testOtherBalloonsStillGoOneADay() {
        var g = broke(balloons: 3)
        close(&g, cash: -50_000)
        XCTAssertEqual(g.state.balloons.count, 2)
        close(&g, cash: -50_000)
        XCTAssertEqual(g.state.balloons.count, 1)
        XCTAssertTrue(g.state.flagshipNext)
        XCTAssertEqual(g.state.graceDaysLeft, 1, "two bad closes already counted")
        close(&g, cash: -50_000)
        XCTAssertTrue(g.state.over)
    }

    func testHoldingRescue() throws {
        var g = withHolding(holding: 2_000_000)
        XCTAssertEqual(g.state.region, .abq)
        close(&g, cash: -30_000)
        close(&g, cash: -30_000)
        let r = close(&g, cash: -30_000)
        XCTAssertEqual(g.state.ruinPending, g.state.day - 1)
        XCTAssertTrue(r.events.contains(.ruinPending(.abq)))
        XCTAssertEqual(g.state.balloons.count, 1, "the last balloon waits for the decision")
        XCTAssertFalse(g.state.over)
        g.state.holding.cash = 2_000_000 // Cappadocia's autopilot kept paying in meanwhile
        let cash = g.state.cash
        let q = g.state.rescueQuote
        XCTAssertEqual(q.added, Bankruptcy.rescueTarget - cash)
        // a tenth of €2,000,000 beats three times the money put in and the €100,000 floor
        XCTAssertEqual(q.cost, 200_000)
        XCTAssertGreaterThanOrEqual(q.cost, Int(Double(q.added) / RegionID.abq.fx * 3))
        XCTAssertTrue(q.affordable)
        XCTAssertEqual(q.holdingAfter, 1_800_000)
        XCTAssertTrue(g.acceptHoldingRescue())
        XCTAssertEqual(g.state.cash, Bankruptcy.rescueTarget)
        XCTAssertEqual(g.state.holding.cash, 1_800_000)
        XCTAssertNil(g.state.ruinPending)
        XCTAssertNil(g.state.local.debtDays)
        XCTAssertNotNil(g.state.holding.rescued?[.abq])
        XCTAssertTrue(g.state.hezQueue.contains(.holdingRescued(.abq, cost: 200_000, added: q.added)))
        // once per region: the next time, the region closes
        _ = g.startNight()
        g.startDay()
        close(&g, cash: -30_000)
        close(&g, cash: -30_000)
        close(&g, cash: -30_000)
        XCTAssertNotNil(g.state.ruinPending)
        XCTAssertNotNil(g.state.rescueQuote.usedOn)
        XCTAssertFalse(g.state.rescueQuote.affordable)
        let h1 = g.state.holding.cash
        XCTAssertFalse(g.acceptHoldingRescue())
        XCTAssertEqual(g.state.holding.cash, h1)
    }

    func testRescueMinimumAndPoorHolding() {
        var g = withHolding(holding: 150_000)
        for _ in 0..<3 { close(&g, cash: -10_000) }
        let q = g.state.rescueQuote
        XCTAssertEqual(q.cost, Bankruptcy.rescueMin)
        XCTAssertTrue(q.affordable)
        g.state.holding.cash = 90_000
        XCTAssertFalse(g.state.rescueQuote.affordable)
        XCTAssertFalse(g.acceptHoldingRescue())
        XCTAssertNotNil(g.state.ruinPending)
    }

    func testDecliningClosesTheRegionKeepsHoldingAndSave() throws {
        var g = withHolding(holding: 900_000)
        for _ in 0..<3 { close(&g, cash: -30_000) }
        XCTAssertNotNil(g.state.ruinPending)
        let capBalloons = try XCTUnwrap(g.state.parked[.cap]).state.balloons.count
        let h0 = g.state.holding.cash
        g.closeRegion()
        XCTAssertEqual(g.state.region, .cap)
        XCTAssertEqual(g.state.balloons.count, capBalloons)
        XCTAssertNil(g.state.parked[.abq])
        XCTAssertFalse(g.state.owns(.abq))
        XCTAssertEqual(g.state.holding.cash, h0, "the holding keeps every euro")
        XCTAssertNotNil(g.state.closedOn(.abq))
        XCTAssertFalse(g.state.over)
        XCTAssertNil(g.state.ruinPending)
        XCTAssertNotNil(g.state.barons[.cap])
        XCTAssertTrue(g.state.hezQueue.contains(.regionClosed(.abq, fresh: false, fee: RegionID.abq.entryFee)))
        XCTAssertNotNil(g.state.weather, "a playable morning")
        // the save round-trips
        let back = try JSONDecoder().decode(GameState.self, from: JSONEncoder().encode(g.state))
        XCTAssertEqual(back, g.state)
        // the closed region can be entered again, afresh, for its fee
        XCTAssertTrue(g.state.regionOpen(.abq))
        XCTAssertTrue(g.enterRegion(.abq))
        XCTAssertEqual(g.state.holding.cash, h0 - RegionID.abq.entryFee)
        XCTAssertEqual(g.state.balloons.count, 1)
        XCTAssertEqual(g.state.cash, RegionID.abq.startCash)
        XCTAssertEqual(g.state.chapter, 0)
        XCTAssertNil(g.state.closedOn(.abq))
        XCTAssertNil(g.state.holding.rescued, "never rescued here")
    }

    func testOnlyRegionStartsAfreshWithTheHolding() {
        var g = broke()
        g.state.chapter = 4
        g.state.barons[.cap] = 50
        g.state.holding.cash = 40_000
        for _ in 0..<3 { close(&g, cash: -30_000) }
        XCTAssertNotNil(g.state.ruinPending)
        XCTAssertFalse(g.state.rescueQuote.affordable)
        g.closeRegion()
        XCTAssertEqual(g.state.region, .cap)
        XCTAssertFalse(g.state.over)
        XCTAssertEqual(g.state.balloons.count, 1)
        XCTAssertEqual(g.state.cash, RegionID.cap.startCash)
        XCTAssertEqual(g.state.chapter, 0)
        XCTAssertEqual(g.state.rivals.map(\.name), RegionID.cap.startingRivals().map(\.name))
        XCTAssertEqual(g.state.holding.cash, 40_000)
        XCTAssertNotNil(g.state.barons[.cap])
        XCTAssertNil(g.state.closedOn(.cap))
        XCTAssertTrue(g.state.hezQueue.contains(.regionClosed(.cap, fresh: true, fee: 0)))
        XCTAssertNotNil(g.state.weather)
        // and the day after plays on
        close(&g, cash: 5_000)
        XCTAssertFalse(g.state.over)
    }

    func testCappadociaClosedCanBeEnteredAgain() {
        var g = withHolding(holding: 900_000)
        // back home, broke there
        g.switchRegion(.cap)
        g.state.balloons = [g.state.balloons.first { $0.id == g.state.flagship }!]
        for _ in 0..<3 { close(&g, cash: -30_000) }
        XCTAssertNotNil(g.state.ruinPending)
        g.closeRegion()
        XCTAssertEqual(g.state.region, .abq)
        XCTAssertFalse(g.state.owns(.cap))
        XCTAssertTrue(g.state.regionOpen(.cap))
        XCTAssertFalse(g.state.needsPack(.cap))
        g.state.hezQueue = []
        let h0 = g.state.holding.cash
        XCTAssertTrue(g.enterRegion(.cap))
        XCTAssertEqual(g.state.region, .cap)
        XCTAssertEqual(g.state.holding.cash, h0 - RegionID.cap.entryFee)
        XCTAssertTrue(g.state.hezQueue.contains(.capReentered))
        XCTAssertNil(g.state.holding.closed)
    }

    /// Saves from before v133 have none of the new keys.
    func testOldSaveDecodes() throws {
        let g = broke()
        var json = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(g.state)) as? [String: Any])
        json.removeValue(forKey: "ruinPending")
        var local = try XCTUnwrap(json["local"] as? [String: Any])
        local.removeValue(forKey: "debtDays")
        json["local"] = local
        var holding = try XCTUnwrap(json["holding"] as? [String: Any])
        holding.removeValue(forKey: "rescued")
        holding.removeValue(forKey: "closed")
        json["holding"] = holding
        let back = try JSONDecoder().decode(GameState.self, from: JSONSerialization.data(withJSONObject: json))
        XCTAssertNil(back.ruinPending)
        XCTAssertNil(back.local.debtDays)
        XCTAssertNil(back.holding.rescued)
        XCTAssertEqual(back.graceDaysLeft, Rules.flagshipGraceDays)
    }
}
