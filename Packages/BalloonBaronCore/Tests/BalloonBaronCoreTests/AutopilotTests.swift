import XCTest
@testable import BalloonBaronCore

/// v117: the autopilot opens with 35 balloons and the Baron of Cappadocia; Hezarfen tells you once.
final class AutopilotTests: XCTestCase {
    func testOpensWithBigFleetAndBaron() {
        var g = Game(company: "Test Air", colors: Rules.palettes[0], seed: 3)
        g.state.day = 200
        g.state.lastSelfFly = 200
        g.state.buildings = [.hangar: 4] // v127: room for 48
        for i in 0..<(Rules.autopilotBalloons - g.state.balloons.count - 1) { g.state.balloons.append(Balloon(id: 700 + i, size: .M, name: "B\(i)")) }
        g.state.barons[.cap] = 150
        XCTAssertFalse(g.state.autopilotOK, "one balloon short")
        g.state.balloons.append(Balloon(id: 699, size: .M, name: "Son"))
        XCTAssertTrue(g.state.autopilotOK)
        g.state.barons = [:]
        XCTAssertFalse(g.state.autopilotOK, "Baron of Cappadocia first")
        g.state.barons[.cap] = 150
        g.state.hezQueue = []
        g.startDay()
        XCTAssertTrue((g.state.hezQueue + (g.state.hezLater ?? [])).contains(.tip(.autopilot)))
    }

    func testSelfFlagshipFliesWithoutTheFlightScene() {
        // On autopilot the app ends the day with no flight even when the founder flies the flagship.
        var g = Game(company: "Test Air", colors: Rules.palettes[0], seed: 5)
        g.state.lastSelfFly = g.state.day
        g.startDay()
        let selfPax = g.launch()
        XCTAssertNotNil(selfPax)
        let r = g.finishDay(flight: nil)
        XCTAssertEqual(r.passengers, selfPax)
    }
}
