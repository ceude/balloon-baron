import XCTest
@testable import BalloonBaronCore

/// v134 (TestFlight): a region's "send the profit to the holding" switch survives any number of region switches, days,
/// saves and loads, and can be set for the region you're in (it applies once that region is parked).
final class SendSwitch134Tests: XCTestCase {
    /// Cappadocia and Albuquerque owned, playing in Albuquerque with Cappadocia parked.
    func twoRegions() -> Game {
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
        return g
    }

    func day(_ g: inout Game) {
        g.launch(skip: true)
        g.finishDay(flight: nil)
        g.startDay()
    }

    func reload(_ g: Game) throws -> Game {
        let data = try JSONEncoder().encode(g.state)
        var back = Game(state: try JSONDecoder().decode(GameState.self, from: data))
        back.startDay()
        return back
    }

    func testAParkedRegionStaysOffThroughTravel() throws {
        var g = twoRegions()
        g.switchRegion(.cap)
        g.setSendsToHolding(.abq, false)
        XCTAssertFalse(g.state.holding.sends(.abq))
        for _ in 0..<3 {
            g.switchRegion(.abq)
            day(&g)
            g = try reload(g)
            XCTAssertFalse(g.state.holding.sends(.abq), "off while you play there")
            g.switchRegion(.cap)
            day(&g)
            g = try reload(g)
            XCTAssertFalse(g.state.holding.sends(.abq), "still off back in Cappadocia")
            XCTAssertTrue(g.state.holding.sends(.cap))
        }
        XCTAssertEqual(g.state.holding.keepIn, [.abq])
    }

    func testTheRegionYouAreInCanBeSetAndItAppliesWhenYouLeave() throws {
        var g = twoRegions()
        XCTAssertEqual(g.state.region, .abq)
        g.setSendsToHolding(.abq, false)
        day(&g)
        g = try reload(g)
        XCTAssertFalse(g.state.holding.sends(.abq))
        g.switchRegion(.cap)
        XCTAssertFalse(g.state.holding.sends(.abq), "the choice made while there holds once parked")
        let h0 = g.state.holding.cash, c0 = try XCTUnwrap(g.state.parked[.abq]).state.cash
        g.runAutopilots()
        _ = g.holdingDay()
        XCTAssertGreaterThan(try XCTUnwrap(g.state.parked[.abq]).state.cash, c0, "its profit stays in its own box")
        XCTAssertEqual(g.state.holding.cash, h0 + 0, "nothing reaches the holding from Albuquerque")
        g.switchRegion(.abq)
        g.switchRegion(.cap)
        XCTAssertFalse(g.state.holding.sends(.abq), "leaving and coming back keeps it off")
    }
}
