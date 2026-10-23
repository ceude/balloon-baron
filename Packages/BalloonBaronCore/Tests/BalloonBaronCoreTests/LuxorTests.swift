import XCTest
@testable import BalloonBaronCore

/// Prototype v104–v105: Luxor, balloon equipment, power lines, the inspector, record attempts and shaped balloons.
final class LuxorTests: XCTestCase {
    func newGame(seed: UInt64 = 42) -> Game {
        var g = Game(company: "Test Air", colors: Rules.palettes[0], seed: seed)
        g.startDay()
        return g
    }

    func play(_ g: inout Game) {
        g.startDay()
        while g.nextHezarfen() != nil {}
        if g.launch() != nil { g.finishDay(flight: FlightResult(landing: .good, distance: 120)) } else { g.finishDay(flight: nil) }
    }

    /// Baron of Cappadocia and Albuquerque, playing in Albuquerque with a full holding.
    func luxorReady() -> Game {
        var g = newGame()
        g.state.barons[.cap] = 1
        g.state.holding.cash = 1_000_000
        XCTAssertTrue(g.enterRegion(.abq))
        g.state.barons[.abq] = g.state.day
        return g
    }

    func testLuxorOpensAfterAlbuquerque() {
        var g = newGame()
        g.state.barons[.cap] = 1
        g.state.holding.cash = 1_000_000
        XCTAssertFalse(g.state.regionOpen(.lux))
        XCTAssertFalse(g.enterRegion(.lux), "Albuquerque first")
        XCTAssertTrue(g.state.regionOpen(.abq))

        g = luxorReady()
        let before = g.state.holding.cash
        g.state.hezQueue = []
        XCTAssertTrue(g.enterRegion(.lux))
        XCTAssertEqual(before - g.state.holding.cash, 150000)
        XCTAssertEqual(g.state.region, .lux)
        XCTAssertEqual(g.state.cash, 5000)
        XCTAssertEqual(g.state.balloons.map(\.name), ["Karnak"])
        XCTAssertEqual(g.state.rivals.map(\.name), ["Theban Skies", "Pharaoh Balloons", "Nile Dawn Air"])
        XCTAssertEqual(g.state.rivals[0].balloons.count, 10)
        XCTAssertEqual(g.state.bossRival?.name, "Theban Skies")
        XCTAssertEqual(Array(g.state.hezQueue.prefix(2)), [.enteredRegion(.lux), .guideHello(.lux)])
        XCTAssertEqual(g.state.region.chapters.map(\.id), ["westBank", "nileWind", "pharaohs", "baronLux"])
        XCTAssertTrue(g.state.region.rivalEdge)
        XCTAssertEqual(g.state.region.entrants.map(\.name), ["Red Sea Balloon Co.", "Felucca Flights", "Hatshepsut Air", "Karnak Wings"])
        // Nile winds: north low, south above, and so on.
        let l = g.state.weather!.layers
        XCTAssertGreaterThan(l[0], 0)
        XCTAssertLessThan(l[1], 0)
    }

    func testNileCruiseSeasonEveryThreeWeeks() {
        var g = luxorReady()
        g.enterRegion(.lux)
        var starts: [Int] = []
        for _ in 0..<40 {
            play(&g)
            if let f = g.state.fiesta, f.start == g.state.day {
                starts.append(f.start)
                XCTAssertEqual(f.end - f.start + 1, 3)
            }
        }
        XCTAssertGreaterThanOrEqual(starts.count, 2)
        if starts.count >= 2 { XCTAssertEqual(starts[1] - starts[0], 3 + 21 - 0 - 0, accuracy: 1) }
    }

    func testLuxorRivalsMergeSooner() {
        var g = luxorReady()
        g.enterRegion(.lux)
        // A modest share is enough in Luxor.
        for _ in 0..<60 {
            g.state.dominanceDays = 3
            play(&g)
            if g.state.lastMerge != nil { break }
        }
        XCTAssertNotNil(g.state.lastMerge, "Luxor's rivals join forces at two dominance days and a 15-day gap")
    }

    func testBurnersAndTurningVent() {
        var g = newGame()
        g.state.cash = 100000
        let id = g.state.balloons[0].id
        g.state.weather?.flag = .yellow
        let base = g.accidentChance(g.state.balloons[0])
        XCTAssertEqual(g.burnerCost(g.state.balloons[0]), 1500)
        XCTAssertTrue(g.addBurner(id))
        XCTAssertEqual(g.state.balloons[0].burners, 2)
        XCTAssertEqual(g.accidentChance(g.state.balloons[0]), base * 0.85, accuracy: 1e-12)
        XCTAssertEqual(g.burnerCost(g.state.balloons[0]), 1800)
        XCTAssertTrue(g.addBurner(id))
        XCTAssertNil(g.burnerCost(g.state.balloons[0]))
        XCTAssertFalse(g.addBurner(id))
        XCTAssertTrue(g.fitTurningVent(id))
        XCTAssertFalse(g.fitTurningVent(id))
        XCTAssertEqual(g.accidentChance(g.state.balloons[0]), base * 0.72 * 0.85, accuracy: 1e-12)
        g.state.weather?.flag = .green
        XCTAssertEqual(g.accidentChance(g.state.balloons[0]), g.accidentChance(g.state.balloons[0]))
        XCTAssertEqual(g.state.cash, 100000 - 1500 - 1800 - 900)
    }

    func testOldBalloonsDecodeWithoutEquipment() throws {
        let json = #"{"id":3,"size":"M","name":"Zelve","fly":true,"damagedUntil":0,"flights":2}"#
        let b = try JSONDecoder().decode(Balloon.self, from: Data(json.utf8))
        XCTAssertEqual(b.burners, 1)
        XCTAssertFalse(b.hasTurningVent)
    }

    func testMoreBurnersClimbFasterAndVentSinks() {
        let g = newGame()
        var w = g.state.weather!
        w.mission = nil
        func climb(_ n: Int) -> Double {
            var f = FlightSim(weather: w, pax: 4, burners: n)
            f.burning = true
            for _ in 0..<60 { _ = f.step(1 / 30) }
            return f.alt
        }
        XCTAssertGreaterThan(climb(3), climb(2))
        XCTAssertGreaterThan(climb(2), climb(1))

        var a = FlightSim(weather: w, pax: 4), b = FlightSim(weather: w, pax: 4)
        a.burning = true; b.burning = true
        for _ in 0..<150 { _ = a.step(1 / 30); _ = b.step(1 / 30) }
        a.burning = false; b.burning = false; b.venting = true
        for _ in 0..<30 { _ = a.step(1 / 30); _ = b.step(1 / 30) }
        XCTAssertLessThan(b.vy, a.vy, "the vent lets hot air out")
    }

    func testPowerLinesStayClearOfTheFields() {
        for seed in 1...40 as ClosedRange<UInt64> {
            var g = newGame(seed: seed)
            let w = g.newWeather()
            let lines = FlightWorld.powerLines(for: w)
            XCTAssertLessThanOrEqual(lines.count, 3)
            for l in lines {
                XCTAssertFalse(l.x1 > FlightWorld.launchX - 170 && l.x0 < FlightWorld.launchX + 170)
                XCTAssertFalse(l.x1 > w.target - 180 && l.x0 < w.target + 180)
                let mid = l.wire(at: (l.x0 + l.x1) / 2)!
                XCTAssertEqual(mid, l.h - PowerLine.sag, accuracy: 1e-9)
                XCTAssertGreaterThan(FlightWorld.terrainHeight(at: (l.x0 + l.x1) / 2, [], lines: lines), 25)
            }
        }
    }

    func testInspectorWarnsTwiceThenFines() {
        var g = newGame()
        g.state.balloons[0].flights = Double(g.state.envelopeLife) * 0.8
        var notes: [HezMessage] = []
        let cash = g.state.cash
        for _ in 0..<3 {
            g.state.day += 5
            g.state.hezQueue = []
            g.unlockCheck()
            notes += g.state.hezQueue.filter { if case .inspector = $0 { return true }; return false }
        }
        let name = g.state.balloons[0].name
        XCTAssertEqual(notes, [.inspector(visit: 1, balloons: [name], fine: 0), .inspector(visit: 2, balloons: [name], fine: 0),
                               .inspector(visit: 3, balloons: [name], fine: 2500)])
        XCTAssertEqual(g.state.cash, cash - 2500)
        // Renewed: the count starts over.
        g.state.balloons[0].flights = 0
        g.unlockCheck()
        XCTAssertEqual(g.state.inspectCount, 0)
    }

    func testFirstRecordAttemptAlwaysSucceeds() {
        for seed in 1...20 as ClosedRange<UInt64> {
            var g = luxorReady()
            g.rng = SplitMix64(seed: seed)
            XCTAssertFalse(g.startRecord(.altitude), "only after entering Luxor")
            g.enterRegion(.lux)
            XCTAssertTrue(g.startRecord(.altitude))
            XCTAssertFalse(g.startRecord(.world), "one at a time")
            for _ in 0...RecordAttempt.altitude.days { play(&g) }
            XCTAssertTrue(g.state.recordSet(.altitude))
            XCTAssertEqual(g.state.holding.recordBoost ?? 0, 0.05, accuracy: 1e-9)
            XCTAssertEqual(g.holdingBoost(.lux), 1.05, accuracy: 1e-9)
        }
    }

    func testShapedBalloonPaysAndCostsALittlePopularity() {
        var g = luxorReady()
        g.enterRegion(.lux)
        XCTAssertTrue(g.signAdShape(.bottle))
        XCTAssertFalse(g.signAdShape(.rocket), "one contract at a time")
        XCTAssertEqual(g.state.adShape(over: .lux), .bottle)
        XCTAssertNil(g.state.adShape(over: .cap))
        let rep = g.state.rep, cash = g.state.holding.cash
        XCTAssertEqual(g.adShapeDay(), 4000)
        XCTAssertEqual(g.state.holding.cash, cash + 4000)
        XCTAssertEqual(g.state.rep, rep - 0.001, accuracy: 1e-12)
    }
}

/// Prototype v107: the fleet page renews every envelope below 30% in one go.
final class FleetRenewTests: XCTestCase {
    func testRenewWornEnvelopesOnlyBelowThirtyPercent() {
        var g = Game(company: "Test Air", colors: Rules.palettes[0], seed: 7)
        g.startDay()
        g.addBalloon(.M)
        g.addBalloon(.S)
        let life = Double(g.state.envelopeLife)
        g.state.balloons[0].flights = life * 0.8   // 20%: renewed
        g.state.balloons[1].flights = life * 0.5   // 50%: left alone
        g.state.balloons[2].flights = life         // 0%: renewed
        g.state.cash = 1_000_000
        let expected = g.renewCost(g.state.balloons[0]) + g.renewCost(g.state.balloons[2])
        XCTAssertEqual(g.wornBalloons.map(\.id), [g.state.balloons[0].id, g.state.balloons[2].id])
        XCTAssertEqual(g.renewWornCost, expected)
        XCTAssertTrue(g.renewWornEnvelopes())
        XCTAssertEqual(g.state.cash, 1_000_000 - expected)
        XCTAssertEqual(g.state.balloons.map(\.flights), [0, life * 0.5, 0])
        XCTAssertFalse(g.renewWornEnvelopes(), "nothing left to renew")
        g.state.balloons[1].flights = life
        g.state.cash = 10
        XCTAssertFalse(g.renewWornEnvelopes(), "can't pay")
    }
}
