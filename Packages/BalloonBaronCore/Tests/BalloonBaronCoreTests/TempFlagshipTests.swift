import XCTest
@testable import BalloonBaronCore

/// v110: while the flagship you fly is in repair you may fly another balloon; the flagship comes back by itself.
final class TempFlagshipTests: XCTestCase {
    func fleetGame(seed: UInt64 = 7) -> Game {
        var g = Game(company: "Test Air", colors: Rules.palettes[0], seed: seed)
        g.state.day = 20
        g.state.lastSelfFly = 20
        g.state.cash = 2_000_000
        g.state.balloons.append(Balloon(id: 501, size: .M, name: "Rüzgar"))
        g.state.balloons.append(Balloon(id: 502, size: .L, name: "Toros"))
        g.state.balloons.append(Balloon(id: 503, size: .M, name: "Ekin"))
        for (i, l) in [PilotLevel.senior, .experienced, .experienced].enumerated() {
            g.state.pilots.append(Pilot(id: 600 + i, name: "Pilot \(i)", level: l))
        }
        g.startDay()
        return g
    }

    func testOfferPicksBiggestAndReturnsAfterRepair() {
        var g = fleetGame()
        let orig = g.state.flagship
        XCTAssertTrue(g.tempFlagshipCandidates.isEmpty, "no offer while the flagship is fine")
        g.state.balloons[0].damagedUntil = g.state.day + 3
        XCTAssertEqual(g.tempFlagshipCandidates.map(\.name), ["Toros", "Rüzgar", "Ekin"])
        g.markTempFlagshipAsked()
        XCTAssertTrue(g.tempFlagshipCandidates.isEmpty, "asked once per repair")
        XCTAssertTrue(g.flyTempFlagship(501))
        XCTAssertEqual(g.state.flagship, 501)
        XCTAssertTrue(g.state.isSelf(g.state.balloon(501)!))
        XCTAssertEqual(g.state.status(g.state.balloon(502)!), .ok, "the others still fly with pilots")
        let until = g.state.balloons[0].damagedUntil
        while g.state.day < until {
            g.launch(skip: true)
            _ = g.finishDay(flight: nil)
            g.startDay()
            if g.state.day < until { XCTAssertEqual(g.state.flagship, 501) }
        }
        XCTAssertEqual(g.state.flagship, orig, "back on the day the repair ends")
        XCTAssertNil(g.state.local.flagReturn)
        XCTAssertTrue(g.state.hezQueue.contains(.flagshipBack(Rules.balloonNames[0])))
    }

    func testDeclineKeepsFlagshipAndPilotsFly() {
        var g = fleetGame()
        g.state.balloons[0].damagedUntil = g.state.day + 2
        g.markTempFlagshipAsked()
        XCTAssertEqual(g.state.flagship, g.state.balloons[0].id)
        XCTAssertEqual(g.state.flyingToday.count, 3)
        XCTAssertTrue(g.tempFlagshipCandidates.isEmpty)
    }

    func testChangingFlagshipCancelsReturn() {
        var g = fleetGame()
        let orig = g.state.flagship
        g.state.balloons[0].damagedUntil = g.state.day + 2
        XCTAssertTrue(g.flyTempFlagship(502))
        g.makeFlagship(503)
        for _ in 0..<3 { g.launch(skip: true); _ = g.finishDay(flight: nil); g.startDay() }
        XCTAssertEqual(g.state.flagship, 503)
        XCTAssertNil(g.state.local.flagReturn)
        XCTAssertNotEqual(g.state.flagship, orig)
    }

    /// Many seeds of real days: you crash now and then, answer yes or no at random, sometimes sell the stand-in.
    func testSimulatedReturns() {
        var asked = 0, yes = 0, returned = 0
        for seed in 1...150 as ClosedRange<UInt64> {
            var g = fleetGame(seed: seed)
            var rng = SplitMix64(seed: seed &* 31)
            var seen = Set<String>()
            var expect: FlagReturn?
            for _ in 0..<30 {
                let cands = g.tempFlagshipCandidates
                if let fb = g.state.balloon(g.state.flagship), !cands.isEmpty {
                    let key = "\(fb.id):\(fb.damagedUntil)"
                    XCTAssertFalse(seen.contains(key), "asked twice for one repair")
                    seen.insert(key)
                    asked += 1
                    XCTAssertEqual(cands[0].size.capacity, cands.map(\.size.capacity).max())
                    g.markTempFlagshipAsked()
                    if rng.chance(0.6) {
                        let pick = rng.chance(0.5) ? cands[0] : rng.pick(cands)
                        XCTAssertTrue(g.flyTempFlagship(pick.id))
                        XCTAssertEqual(g.state.status(g.state.balloon(pick.id)!), .ok)
                        expect = FlagReturn(original: fb.id, temp: pick.id)
                        yes += 1
                    }
                }
                if let e = expect, rng.chance(0.03), g.sellBalloon(e.temp) { expect = nil }
                g.state.hezQueue = []
                var landing = FlightResult.Landing.good
                if rng.chance(0.2) { landing = .crash }
                if g.launch(skip: false) != nil {
                    _ = g.finishDay(flight: FlightResult(landing: landing, distance: 120, mission: nil, missionDone: false))
                } else {
                    _ = g.finishDay(flight: nil)
                }
                g.startDay()
                if let e = expect, let o = g.state.balloon(e.original) {
                    if o.damagedUntil > g.state.day {
                        XCTAssertEqual(g.state.flagship, e.temp, "stays on the stand-in during repair")
                    } else {
                        XCTAssertEqual(g.state.flagship, e.original, "returns once repaired")
                        XCTAssertNil(g.state.local.flagReturn)
                        XCTAssertTrue(g.state.hezQueue.contains(.flagshipBack(o.name)))
                        returned += 1
                        expect = nil
                    }
                }
            }
        }
        XCTAssertGreaterThan(asked, 50)
        XCTAssertGreaterThan(yes, 30)
        XCTAssertGreaterThan(returned, 25)
        print("temp flagship sim: asked \(asked), yes \(yes), returned \(returned)")
    }

    func testOldSaveDecodes() throws {
        let g = fleetGame()
        var json = try JSONSerialization.jsonObject(with: JSONEncoder().encode(g.state.local)) as! [String: Any]
        json.removeValue(forKey: "flagReturn")
        json.removeValue(forKey: "flagAskedUntil")
        let back = try JSONDecoder().decode(RegionState.self, from: JSONSerialization.data(withJSONObject: json))
        XCTAssertNil(back.flagReturn)
    }

    /// v111: name your balloons; pick the one you fly from its card.
    func testRenameAndFlyMyself() {
        var g = fleetGame()
        XCTAssertEqual(g.renameBalloon(502, "  Ekin   Yıldızı  "), .ok)
        XCTAssertEqual(g.state.balloon(502)?.name, "Ekin Yıldızı")
        XCTAssertEqual(g.renameBalloon(503, "rüzgar"), .taken, "names are unique, whatever the case")
        XCTAssertEqual(g.renameBalloon(503, "   "), .empty)
        XCTAssertEqual(g.renameBalloon(503, String(repeating: "a", count: 40)), .ok)
        XCTAssertEqual(g.state.balloon(503)?.name.count, Rules.balloonNameMax)
        g.setSelfFly(false)
        XCTAssertTrue(g.flyMyself(502))
        XCTAssertEqual(g.state.flagship, 502)
        XCTAssertTrue(g.state.isSelf(g.state.balloon(502)!))
        g.state.balloons[1].damagedUntil = g.state.day + 2
        XCTAssertFalse(g.flyMyself(501), "not a balloon in repair")
    }
}
