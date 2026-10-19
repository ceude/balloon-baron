import XCTest
@testable import BalloonBaronCore

final class FlightTests: XCTestCase {
    func weather(_ flag: Flag = .green, mission: Mission? = nil) -> Weather {
        Weather(flag: flag, surfaceWind: 5, layers: [-1, 4, 2, -3], target: 1600, seed: 12345, mission: mission, valley: 900)
    }

    func testMulberryMatchesThePrototype() {
        // mulberry32(5) in JavaScript gives 0.68977..., 0.77274... for its first two draws.
        var r = Mulberry32(seed: 5)
        XCTAssertEqual(r.next(), 0.689_774_910_919_368_3, accuracy: 1e-12)
        XCTAssertEqual(r.next(), 0.772_743_273_293_599_5, accuracy: 1e-12)
    }

    func testObstaclesStayAwayFromTheFields() {
        let w = weather(mission: .valley)
        for o in FlightWorld.obstacles(for: w) {
            XCTAssertGreaterThanOrEqual(abs(o.x - FlightWorld.launchX), 160)
            XCTAssertGreaterThanOrEqual(abs(o.x - w.target), 140)
            XCTAssertGreaterThanOrEqual(abs(o.x - w.valley), 110)
        }
    }

    func testWindBlendsBetweenLayers() {
        let w = weather()
        XCTAssertEqual(FlightWorld.wind(at: 0, time: 0, w), -1, accuracy: 0.4)
        XCTAssertEqual(FlightWorld.wind(at: 600, time: 0, w), -3, accuracy: 0.4)
    }

    func testBurnerClimbsAndCoolingLands() {
        var f = FlightSim(weather: weather(), pax: 8)
        f.burning = true
        var events: [FlightSim.Event] = []
        for _ in 0..<200 { events += f.step(1 / 30) }
        XCTAssertTrue(f.airborne)
        XCTAssertTrue(events.contains(.airborne))
        XCTAssertGreaterThan(f.alt, 15)
        XCTAssertLessThan(f.fuel, 100)
        f.burning = false
        for _ in 0..<20000 where !f.done { events += f.step(1 / 30) }
        XCTAssertTrue(f.done)
        XCTAssertNotNil(f.result)
        XCTAssertEqual(events.last, .landed)
    }

    func testCancelOnlyBeforeTakeOff() {
        var f = FlightSim(weather: weather(mission: .proposal), pax: 8)
        f.cancel()
        XCTAssertEqual(f.result?.landing, .cancel)
        XCTAssertEqual(f.result?.mission, .proposal)
    }

    func testProposalNeedsEightSecondsInTheBand() {
        var f = FlightSim(weather: weather(mission: .proposal), pax: 2)
        f.airborne = true
        f.alt = 300
        f.heat = 0.5
        var done = false
        for _ in 0..<(30 * 9) where !done {
            f.alt = 300; f.vy = 0
            done = f.step(1 / 30).contains(.missionDone)
        }
        XCTAssertTrue(done)
        XCTAssertGreaterThanOrEqual(f.missionProgress, 8)
    }
}
