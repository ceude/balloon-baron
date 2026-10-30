import XCTest
@testable import BalloonBaronCore

/// v124.6: why passengers come, why stars moved, seat goals, missions that grow with the company.
final class NewPlayerTests: XCTestCase {
    func newGame(seed: UInt64 = 11) -> Game {
        var g = Game(company: "Test Air", colors: Rules.palettes[0], seed: seed)
        g.startDay()
        return g
    }

    func testFleetGoalsCountSeats() {
        var g = newGame()
        XCTAssertEqual(RegionID.cap.chapters[0].goals.first { $0.kind == .seats }?.target, 16)
        XCTAssertFalse(RegionID.cap.chapters.flatMap(\.goals).contains { $0.kind == .balloons })
        XCTAssertEqual(g.state.value(.seats), 8)
        g.state.cash = 100_000
        _ = g.buyBalloon(.M)
        XCTAssertEqual(g.state.value(.seats), 24)
    }

    func testMissionRewardGrowsWithTheDailyNet() {
        var g = newGame()
        XCTAssertEqual(g.missionReward(.proposal, .M), 900, "early on the old reward stands")
        g.state.local.netHistory = Array(repeating: 28_000, count: 14)
        XCTAssertEqual(g.missionReward(.proposal, .M), 2520) // 28,000 × 8% × 450/400
        XCTAssertEqual(g.missionReward(.panorama, .M), 1400)
    }

    func testEmptySeatCause() {
        var g = newGame()
        g.state.price = 300
        XCTAssertEqual(g.emptySeatCause, .price)
        g.state.price = 170
        g.state.rep = 0.45
        XCTAssertEqual(g.emptySeatCause, .priceRep)
        g.state.rep = 1.1
        g.state.price = 150
        XCTAssertEqual(g.emptySeatCause, .priceRiv)
        XCTAssertNotNil(g.popularityPull)
    }

    func testReportSaysWhyStarsMoved() {
        var g = newGame()
        if g.state.weather?.flag == .red { g.state.weather?.flag = .green }
        g.state.selfFlights = 5 // past the beginner's protection
        guard g.launch(skip: false) != nil else { return XCTFail("the flagship should fly") }
        let r = g.finishDay(flight: FlightResult(landing: .hard, distance: 60))
        XCTAssertNotNil(r.repFrom)
        XCTAssertLessThan(r.repTo!, r.repFrom!)
        XCTAssertEqual(r.repReasons.first?.0, .hard)
        XCTAssertEqual(r.repWhy?[.hard] ?? 0, -(0.08 + 0.15 * 0.3), accuracy: 1e-9)
        XCTAssertNil(g.repLog)
    }

    func testFieldIsCloseOnTheFirstDays() {
        XCTAssertEqual(TutorialScene.target[1], 1300)
        var g = newGame()
        g.state.tutorial = nil
        g.state.day = 3
        for _ in 0..<20 { let t = g.newWeather().target; XCTAssertTrue((1220...1470).contains(t), "\(t)") }
    }
}
