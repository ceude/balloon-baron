import XCTest
@testable import BalloonBaronCore

/// v141.4 (TestFlight): a parked region whose baron title you haven't won keeps its autopilot profit in its own cash
/// box whatever its send switch says; once you're its baron the switch works as before, as the player left it.
final class SendBaron1414Tests: XCTestCase {
    /// Baron of Cappadocia, Albuquerque entered but not won, back in Cappadocia with Albuquerque parked.
    func abqParked() -> Game {
        var g = Game(company: "Test Air", colors: Rules.palettes[0], seed: 42)
        g.state.tutorial = TutorialState(done: true)
        g.startDay()
        g.state.chapter = 4
        g.state.barons[.cap] = 1
        g.grantStoreItem(.worldTour)
        g.state.local.netHistory = [20000, 22000, 24000]
        g.state.holding.cash = 200_000
        g.state.cash = 50_000
        XCTAssertTrue(g.enterRegion(.abq))
        g.switchRegion(.cap)
        XCTAssertNotNil(g.state.parked[.abq])
        XCTAssertFalse(g.state.isBaron(.abq))
        return g
    }

    func evening(_ g: inout Game) -> (holding: Int, abq: Int) {
        let h0 = g.state.holding.cash, c0 = g.state.parked[.abq]?.state.cash ?? 0
        g.runAutopilots()
        _ = g.holdingDay()
        return (g.state.holding.cash - h0, (g.state.parked[.abq]?.state.cash ?? 0) - c0)
    }

    func testANonBaronRegionKeepsItsProfitWithTheSwitchOn() {
        var g = abqParked()
        XCTAssertTrue(g.state.holding.sends(.abq), "the switch is on by default")
        XCTAssertFalse(g.state.sendsToHolding(.abq))
        let d = evening(&g)
        XCTAssertGreaterThan(d.abq, 0, "the profit stays in Albuquerque's cash box")
        XCTAssertEqual(d.holding, 0, "nothing reaches the holding")
        XCTAssertEqual(g.state.parked[.abq]?.auto.kept, d.abq)
    }

    func testOnceBaronItSends() {
        var g = abqParked()
        g.state.barons[.abq] = g.state.day
        XCTAssertTrue(g.state.sendsToHolding(.abq))
        let d = evening(&g)
        XCTAssertEqual(d.abq, 0, "the profit no longer stays in the region")
        XCTAssertGreaterThan(d.holding, 0, "it reaches the holding")
    }

    func testTheSwitchIsKeptThroughTheBaronTitle() throws {
        var g = abqParked()
        g.setSendsToHolding(.abq, false)
        _ = evening(&g)
        let back = Game(state: try JSONDecoder().decode(GameState.self, from: JSONEncoder().encode(g.state)))
        g = back
        XCTAssertFalse(g.state.holding.sends(.abq), "the player's choice is stored as made")
        g.state.barons[.abq] = g.state.day
        XCTAssertFalse(g.state.sendsToHolding(.abq), "baron now, but the player turned it off")
        XCTAssertGreaterThan(evening(&g).abq, 0)
        g.setSendsToHolding(.abq, true)
        XCTAssertTrue(g.state.sendsToHolding(.abq))
        XCTAssertGreaterThan(evening(&g).holding, 0)
    }

    func testManualTransferStillWorksBeforeBaron() {
        var g = abqParked()
        g.state.parked[.abq]?.state.cash = 40_000
        let moved = g.withdraw(from: .abq, share: 1)
        XCTAssertEqual(moved, 40_000 - Holding.withdrawKeep(.abq))
    }
}

/// v141.4 (TestFlight): reviews belong to their region.
final class RegionReviews1414Tests: XCTestCase {
    func testTheGoremeLocalOnlyWelcomes() {
        var g = Game(company: "Test Air", colors: Rules.palettes[0], seed: 7)
        let local = Review.reviewers.count - 1
        XCTAssertEqual(Review.reviewers[local].country, "goreme")
        for _ in 0..<400 { g.addReview(.influencer) }
        XCTAssertFalse(g.state.reviews.contains { $0.kind != .welcome && $0.reviewer == local })
    }
}
