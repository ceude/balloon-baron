import XCTest
@testable import BalloonBaronCore

/// v121: the Hasan story. Kenan greets you on the first morning in Cappadocia; Hezarfen tells the grandfather's story
/// after the first flight.
final class StoryTests: XCTestCase {
    func testKenanOnDayOneThenHasanAfterTheFirstFlight() {
        var g = Game(company: "Test Air", colors: Rules.palettes[0], seed: 3)
        g.startDay()
        XCTAssertNotNil(g.state.bossRival)
        XCTAssertTrue(g.state.hezQueue.contains(.boss(.cap, .hello)), "Kenan speaks on day 1")
        XCTAssertFalse(g.state.hezQueue.contains(.tip(.hasan)))
        g.state.hezQueue = []
        _ = g.launch()
        _ = g.finishDay(flight: nil)
        XCTAssertTrue(g.state.hezQueue.contains(.tip(.hasan)), "the story after the first flight")
    }

    func testNoHasanStoryLateInAnOldSave() {
        var g = Game(company: "Test Air", colors: Rules.palettes[0], seed: 4)
        g.state.day = 40
        g.state.lastSelfFly = 40
        g.startDay()
        _ = g.launch()
        _ = g.finishDay(flight: nil)
        XCTAssertFalse(g.state.hezQueue.contains(.tip(.hasan)))
    }
}

/// TestFlight: before hotels and guides open, popularity isn't capped and Hezarfen doesn't send you to them.
final class EarlyCapTests: XCTestCase {
    func testNoCapBeforeTheMarket() {
        var g = Game(company: "Test Air", colors: Rules.palettes[0], seed: 5)
        g.startDay()
        g.state.rep = 1.3
        g.launch(skip: true)
        g.finishDay(flight: nil)
        XCTAssertGreaterThan(g.state.rep, Rules.prCap)
        XCTAssertFalse(g.state.hezQueue.contains(.tip(.prcap)))
    }
}
