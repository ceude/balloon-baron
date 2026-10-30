import XCTest
@testable import BalloonBaronCore

/// v111: what the first TestFlight players stumbled on: the wind layers, a crash on the first flight, the price.
final class CoachTests: XCTestCase {
    func testWindChangesAtTheDashedLine() {
        let w = Weather(flag: .green, surfaceWind: 5, layers: [-2, -2, 3, 4], target: 1800, seed: 1, mission: nil, valley: 900)
        // The wind without its gusts (time 0).
        func calm(_ alt: Double) -> Double {
            FlightWorld.wind(at: alt, time: 0, w) - w.flag.gust * 0.6 * (sin(alt * 0.013) + 0.6 * sin(alt * 0.031))
        }
        // Well inside a band its own wind blows; just over the 180 m line it's already the next layer's.
        XCTAssertEqual(calm(160), -2, accuracy: 0.01)
        XCTAssertEqual(calm(195), 3, accuracy: 0.01)
        XCTAssertEqual(calm(180), 0.5, accuracy: 0.01, "half way at the line itself")
    }

    func testRookieCrashIsOneDayAndCounted() {
        var g = Game(company: "Test Air", colors: Rules.palettes[0], seed: 5)
        g.startDay()
        XCTAssertEqual(g.state.selfFlights ?? 0, 0)
        if g.launch(skip: false) != nil {
            let r = g.finishDay(flight: FlightResult(landing: .crash, distance: 400))
            XCTAssertTrue(r.events.contains(.rookieRepair))
            XCTAssertEqual(g.state.balloons[0].damagedUntil, g.state.day, "back the next morning")
            XCTAssertEqual(g.state.selfFlights, 1)
        } else { XCTFail("day one should fly") }
        g.state.selfFlights = Rules.coachFlights
        g.state.balloons[0].damagedUntil = 0
        g.startDay()
        if g.state.weather?.flag == .red { g.state.weather?.flag = .green }
        if g.launch(skip: false) != nil {
            let r = g.finishDay(flight: FlightResult(landing: .crash, distance: 400))
            XCTAssertFalse(r.events.contains(.rookieRepair))
            XCTAssertGreaterThan(g.state.balloons[0].damagedUntil, g.state.day)
        }
    }

    func testPriceTipWhenSeatsStayEmpty() {
        var g = Game(company: "Test Air", colors: Rules.palettes[0], seed: 5)
        g.state.day = 2
        g.state.local.lastShare = MarketShare(me: 7, cap: 8, rivals: [], demand: 50, extra: 0)
        g.startDay()
        let q = g.state.hezQueue + (g.state.hezLater ?? [])
        XCTAssertTrue(q.contains(.tip(.price)) || q.contains(.tip(.priceRep)) || q.contains(.tip(.priceRiv)))
    }
}
