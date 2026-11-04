import XCTest
@testable import BalloonBaronCore

/// v131 (TestFlight: "all four layers blew away from the field, I had to cancel"): every day's winds can take you to the
/// landing field through a layer you can actually fly in.
final class WindReachTests: XCTestCase {
    /// Many seeds, every region, summer and winter, early and late days.
    func days(_ n: Int, _ body: (RegionID, Weather) -> Void) {
        for r in [RegionID.cap, .abq, .lux, .bri, .mara] { // v141: the Maasai Mara too
            for seed in 0..<n {
                var g = Game(company: "T", colors: ["#ffffff", "#000000"], seed: UInt64(seed) &* 7919 &+ 13)
                g.state.region = r
                g.state.day = 3 + seed % 400
                if seed % 4 == 0 { g.state.winter = Winter(start: g.state.day, end: g.state.day + 5) }
                body(r, g.newWeather())
            }
        }
    }

    func testEveryDayHasAUsableLayerTowardTheField() {
        var flags: [Flag: Int] = [:]
        days(2500) { r, w in
            flags[w.flag, default: 0] += 1
            XCTAssertGreaterThan(w.target, FlightWorld.launchX)
            XCTAssertFalse(FlightWorld.usableLayers(w).contains(0), "the bottom layer is among the chimneys")
            XCTAssertGreaterThanOrEqual(FlightWorld.towardWind(w), Rules.minTowardWind, "\(r) \(w.flag) \(w.layers)")
            XCTAssertTrue(w.layers.contains { $0 < -0.5 }, "and one that brings you back")
            if let a = w.air, r == .bri {
                XCTAssertFalse(FlightWorld.usableLayers(w).contains(3), "the airspace (floor \(a.floor)) closes the top layer")
            }
        }
        XCTAssertGreaterThan(flags[.green] ?? 0, 0)
        XCTAssertGreaterThan(flags[.yellow] ?? 0, 0)
        XCTAssertGreaterThan(flags[.red] ?? 0, 0)
    }

    /// The old rule counted the surface wind: a red Cappadocia day with only the bottom layer blowing east.
    func testTheBottomLayerAloneIsNotEnough() {
        let w = Weather(flag: .red, surfaceWind: 28, layers: [3.5, -2, -4, -6], target: 1600, seed: 1, mission: nil, valley: 900)
        XCTAssertLessThan(FlightWorld.towardWind(w), Rules.minTowardWind)
    }

    /// A simple pilot climbs into the best usable layer and holds it: every green and yellow day reaches the field without
    /// hitting anything, with fuel to spare.
    func testABotFliesToTheFieldOnEveryFlyableDay() {
        let hold: [Double] = [30, 145, 265, 470]
        days(300) { r, w in
            guard w.flag != .red else { return }
            let use = FlightWorld.usableLayers(w)
            let i = use.max { w.layers[$0] < w.layers[$1] }!
            var f = FlightSim(weather: w, pax: 8, region: r)
            var steps = 0
            while !f.done && f.x < w.target - 120 && steps < 30 * 600 {
                f.burning = f.alt + f.vy * 6 < hold[i]
                _ = f.step(1 / 30)
                steps += 1
            }
            XCTAssertFalse(f.done, "\(r) \(w.flag) \(w.layers): came down at x \(Int(f.x))")
            XCTAssertGreaterThanOrEqual(f.x, w.target - 120, "\(r) \(w.layers): stuck at x \(Int(f.x)) after \(steps / 30) s")
            XCTAssertGreaterThan(f.fuel, 0)
            if let a = w.air { XCTAssertFalse(f.airspaceFined, "flew into the airspace (floor \(a.floor))") }
        }
    }
}
