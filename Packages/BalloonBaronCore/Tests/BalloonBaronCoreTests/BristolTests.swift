import XCTest
@testable import BalloonBaronCore

/// Prototype v124: Bristol, the fourth region.
final class BristolTests: XCTestCase {
    func newGame(seed: UInt64 = 42) -> Game {
        var g = Game(company: "Test Air", colors: Rules.palettes[0], seed: seed)
        g.startDay()
        return g
    }

    func play(_ g: inout Game, landing: FlightResult = FlightResult(landing: .good, distance: 120)) {
        g.startDay()
        while g.nextHezarfen() != nil {}
        if g.launch() != nil { g.finishDay(flight: landing) } else { g.finishDay(flight: nil) }
    }

    /// Baron of Cappadocia, Albuquerque and Luxor, playing in Luxor with a full holding.
    func bristolReady(seed: UInt64 = 42) -> Game {
        var g = newGame(seed: seed)
        g.state.barons[.cap] = 1
        g.grantStoreItem(.worldTour)
        g.state.holding.cash = 2_000_000
        XCTAssertTrue(g.enterRegion(.abq))
        g.state.barons[.abq] = g.state.day
        XCTAssertTrue(g.enterRegion(.lux))
        return g
    }

    func inBristol(seed: UInt64 = 42) -> Game {
        var g = bristolReady(seed: seed)
        g.state.barons[.lux] = g.state.day
        XCTAssertTrue(g.enterRegion(.bri))
        return g
    }

    func testBristolOpensAfterLuxorBaron() {
        var g = bristolReady()
        XCTAssertFalse(g.state.regionOpen(.bri))
        XCTAssertFalse(g.enterRegion(.bri), "Luxor's baron first")
        g.state.barons[.lux] = g.state.day
        XCTAssertTrue(g.state.regionOpen(.bri))
        let before = g.state.holding.cash
        g.state.hezQueue = []
        XCTAssertTrue(g.enterRegion(.bri))
        XCTAssertEqual(before - g.state.holding.cash, 240_000) // £200,000 at £1 = €1.20
        XCTAssertEqual(g.state.region, .bri)
        XCTAssertEqual(g.state.cash, 6000)
        XCTAssertEqual(g.state.price, 185)
        XCTAssertEqual(g.state.demandBase, 145)
        XCTAssertEqual(g.state.local.fogFlown, 0)
        XCTAssertEqual(g.state.local.glowCount, 0)
        XCTAssertEqual(g.state.balloons.map(\.name), ["Clifton"])
        XCTAssertEqual(g.state.rivals.map(\.name), ["Clifton Crown Balloons", "Severn Sky Co.", "Harbourside Air"])
        XCTAssertEqual(g.state.rivals.map(\.balloons.count), [11, 7, 6])
        XCTAssertEqual(g.state.bossRival?.name, "Clifton Crown Balloons")
        XCTAssertEqual(Array(g.state.hezQueue.prefix(2)), [.enteredRegion(.bri), .guideHello(.bri)])
        XCTAssertEqual(g.state.region.entrants.map(\.name), ["Cotswold Air Holidays", "Cheap Skies Bristol", "Royal Crescent Flights", "Mendip Balloon Co."])
        XCTAssertTrue(g.state.region.rivalEdge)
        XCTAssertTrue(g.state.region.mergesEarly)
        XCTAssertEqual(g.state.region.xlName, "Avon Yıldızı")
    }

    func testBristolNeedsTheGrandTour() {
        var g = newGame()
        for r in [RegionID.cap, .abq, .lux] { g.state.barons[r] = 1 }
        g.state.holding.cash = 1_000_000
        XCTAssertTrue(g.state.needsPack(.bri))
        XCTAssertFalse(g.enterRegion(.bri))
        g.grantStoreItem(.worldTour)
        XCTAssertTrue(g.enterRegion(.bri))
    }

    func testPoundsToTheHolding() {
        XCTAssertEqual(RegionID.bri.currency, "GBP")
        XCTAssertEqual(RegionID.bri.fx * 1.2, 1, accuracy: 1e-12)
        var g = inBristol()
        g.state.cash = 40000
        let h = g.state.holding.cash
        XCTAssertEqual(g.withdraw(share: 1), 30000)
        // £30,000 leaves £10,000 behind and reaches the holding as euros at £1 = €1.20: €36,000.
        XCTAssertEqual(g.state.cash, 10000)
        XCTAssertEqual(g.state.holding.cash - h, 36000)
    }

    func testPilotsCostMoreInBristol() {
        var g = inBristol()
        g.newCandidates()
        for p in g.state.candidates where !p.fromSchool {
            XCTAssertEqual(p.wage, Pilot.baseWage(p.level, school: false, trait: p.trait, region: .bri))
            XCTAssertEqual(Double(p.wage), Double(Pilot.baseWage(p.level, school: false, trait: p.trait)) * 1.15, accuracy: 1)
        }
    }

    func testChaptersAndProgress() {
        var g = inBristol()
        let cs = g.state.region.chapters
        XCTAssertEqual(cs.map(\.id), ["ashton", "avonGorge", "festivalBri", "baronBri"])
        XCTAssertEqual(cs.map(\.reward), [5000, 10000, 20000, 0])
        func target(_ c: Int, _ k: GoalKind) -> Double? { cs[c].goals.first { $0.kind == k }?.target }
        XCTAssertEqual([target(0, .balloons), target(1, .balloons), target(2, .balloons)], [4, 14, 24])
        XCTAssertEqual([target(1, .share), target(2, .share), target(3, .share)], [0.35, 0.55, 0.75])
        XCTAssertEqual(target(1, .fog), 1)
        XCTAssertEqual(target(2, .glow), 1)
        XCTAssertTrue(GoalKind.fog.yesNo && GoalKind.glow.yesNo)
        XCTAssertEqual(g.state.value(.fog), 0)
        g.state.local.fogFlown = 2
        g.state.local.glowCount = 1
        XCTAssertEqual(g.state.value(.fog), 2)
        XCTAssertTrue(g.state.done(Goal(kind: .glow, target: 1)))
        // The first chapter done the moment its goals hold.
        g.state.cash = 1_000_000
        for _ in 0..<3 { _ = g.buyBalloon(.S) }
        g.state.pilots = (0..<3).map { Pilot(id: 900 + $0, name: "P", level: .experienced) }
        g.state.rep = 1.25
        g.state.hotelDeals = [.stone, .mansion]
        g.state.guideCount = 1
        g.state.buildings = [.mast: 2]
        XCTAssertTrue(g.finishChapterNow())
        XCTAssertEqual(g.state.chapter, 1)
        XCTAssertEqual(g.state.chapterNews, ChapterNews(region: .bri, index: 0))
    }

    /// The fog and the airspace come with the weather, from the seeded generator: the same seed, the same day.
    func testFogAndAirspaceRollsAreSeededAndInRange() {
        var fog = 0, air = 0, flyable = 0
        for seed in 1...300 as ClosedRange<UInt64> {
            var a = inBristol(seed: seed), b = inBristol(seed: seed)
            XCTAssertEqual(a.newWeather(), b.newWeather())
            let w = a.newWeather()
            if w.flag == .red { XCTAssertNil(w.fog); XCTAssertNil(w.air); continue }
            flyable += 1
            if let f = w.fog { fog += 1; XCTAssertTrue((90...150).contains(f.top)) }
            if let s = w.air {
                air += 1
                XCTAssertGreaterThanOrEqual(s.x0, 220 + 380)
                XCTAssertTrue((420...620).contains(s.x1 - s.x0))
                XCTAssertTrue((340...410).contains(s.floor))
            }
            XCTAssertTrue((1220...1920).contains(w.target))
        }
        XCTAssertEqual(Double(fog) / Double(flyable), 0.28, accuracy: 0.08)
        XCTAssertEqual(Double(air) / Double(flyable), 0.4, accuracy: 0.08)
        // Elsewhere: never.
        var g = newGame()
        for _ in 0..<50 { let w = g.newWeather(); XCTAssertNil(w.fog); XCTAssertNil(w.air) }
    }

    func testMoreYellowFlagsAndWestWind() {
        var g = inBristol()
        var n: [Flag: Int] = [:]
        for _ in 0..<3000 { n[g.rollFlag(), default: 0] += 1 }
        XCTAssertEqual(Double(n[.green]!) / 3000, 0.42, accuracy: 0.03)
        XCTAssertEqual(Double(n[.yellow]!) / 3000, 0.43, accuracy: 0.03)
        for _ in 0..<40 {
            let w = g.newWeather()
            XCTAssertGreaterThan(w.layers[1], 0, "east at mid heights")
            XCTAssertGreaterThan(w.layers[2], 0)
        }
    }

    func testBridgeIsAnObstacleAndTheWorldIsSeeded() {
        XCTAssertEqual(BristolWorld.bridgeHeight(0), 62)
        XCTAssertEqual(BristolWorld.bridgeHeight(100), 108)
        XCTAssertEqual(BristolWorld.bridgeHeight(-100), 108)
        XCTAssertEqual(BristolWorld.bridgeHeight(108.5), 52, accuracy: 1)
        XCTAssertEqual(BristolWorld.bridgeHeight(200), 0)
        var bridges = 0
        for seed in 1...60 as ClosedRange<UInt64> {
            var g = inBristol(seed: seed)
            let w = g.newWeather()
            let a = FlightSim(weather: w, pax: 4, region: .bri), b = FlightSim(weather: w, pax: 4, region: .bri)
            XCTAssertEqual(a.bristol, b.bristol)
            XCTAssertEqual(a.obstacles, b.obstacles)
            guard let B = a.bristol else { return XCTFail("Bristol's world") }
            XCTAssertFalse(a.obstacles.contains { $0.kind == .plain })
            if let x = B.bridge {
                bridges += 1
                XCTAssertGreaterThan(abs(x - FlightWorld.launchX), 180 + BristolWorld.halfWidth - 1)
                XCTAssertGreaterThan(abs(x - w.target), 190 + BristolWorld.halfWidth - 1)
                XCTAssertEqual(FlightWorld.terrainHeight(at: x, a.obstacles, lines: a.lines, bristol: B), 62, accuracy: 1e-9)
            }
            // The launch and landing fields stay clear of animals and mud.
            for x in [FlightWorld.launchX, w.target] { XCTAssertNil(B.pen(at: x)); XCTAssertFalse(B.mud(at: x)) }
            XCTAssertNil(FlightSim(weather: w, pax: 4).bristol, "only in Bristol")
        }
        XCTAssertGreaterThan(bridges, 30)
    }

    func testFlyingUnderTheDeckCrashesIntoTheBridge() {
        var g = inBristol(seed: 7)
        var w = g.newWeather()
        for s in 8...200 as ClosedRange<UInt64> where FlightSim(weather: w, pax: 4, region: .bri).bristol?.bridge == nil {
            g = inBristol(seed: s); w = g.newWeather()
        }
        var f = FlightSim(weather: w, pax: 4, region: .bri)
        let x = f.bristol!.bridge!
        f.airborne = true
        f.x = x
        f.alt = 30
        f.heat = 0.5
        f.vy = 0
        _ = f.step(1 / 60)
        XCTAssertTrue(f.done)
        XCTAssertEqual(f.result?.landing, .crash)
        XCTAssertEqual(f.hit, .bridge)
    }

    func testAirspaceWarnsThenFinesAfterThreeSeconds() {
        var g = inBristol()
        var w = g.newWeather()
        w.flag = .green
        w.air = Airspace(x0: 900, x1: 1400, floor: 350)
        w.layers = [0, 0, 0, 0]
        var f = FlightSim(weather: w, pax: 4, region: .bri)
        f.airborne = true
        f.x = 1000
        f.alt = 420
        f.heat = 0.5
        var ev: [FlightSim.Event] = []
        for _ in 0..<(60 * 4) { f.vy = 0; f.alt = 420; ev += f.step(1 / 60) }
        XCTAssertEqual(ev.filter { $0 == .airspaceWarning }.count, 1)
        XCTAssertEqual(ev.filter { $0 == .airspaceViolated }.count, 1)
        XCTAssertTrue(f.airspaceFined)
        f.land(nil)
        XCTAssertEqual(f.result?.airFine, true)
    }

    func testLivestockMudAndAirportAtTheEndOfTheDay() {
        var g = inBristol()
        g.state.day = 20
        g.state.weather?.flag = .green
        g.state.weather?.fog = nil
        g.startDay()
        while g.nextHezarfen() != nil {}
        g.state.weather?.flag = .green
        g.state.weather?.fog = Fog(top: 120)
        XCTAssertNotNil(g.launch())
        let rep = g.state.rep
        var f = FlightResult(landing: .good, distance: 120)
        f.farm = .cow
        f.mud = true
        f.airFine = true
        let r = g.finishDay(flight: f)
        XCTAssertEqual(r.ledger.fines, 300 + 1500)
        XCTAssertTrue(r.events.contains(.farmLanding(.cow, fine: 300)))
        XCTAssertTrue(r.events.contains(.mudLanding))
        XCTAssertTrue(r.events.contains(.airspaceFine(fine: 1500)))
        XCTAssertTrue(r.events.contains(.fogFlown))
        XCTAssertEqual(g.state.local.fogFlown, 1)
        XCTAssertTrue(g.state.reviews.contains { $0.kind == .farm })
        XCTAssertTrue(g.state.reviews.contains { $0.kind == .mud })
        XCTAssertTrue((g.state.paperNext ?? []).contains(.airspace(fine: 1500)))
        XCTAssertLessThan(g.state.rep, rep)
    }

    func testFestivalEveningAscentAndNightGlow() {
        var g = inBristol()
        g.state.cash = 100_000
        for _ in 0..<4 { _ = g.buyBalloon(.M) }
        g.state.pilots = (0..<5).map { Pilot(id: 900 + $0, name: "P", level: .senior) }
        g.assignPilots()
        XCTAssertEqual(g.glowState, .noFestival)
        g.state.fiesta = Fiesta(start: g.state.day, end: g.state.day + 3)
        g.state.weather?.flag = .green
        XCTAssertEqual(g.glowState, .ok)
        let cash = g.state.cash
        XCTAssertTrue(g.bookGlow())
        XCTAssertEqual(g.state.cash, cash - Glow.cost)
        XCTAssertEqual(g.glowState, .booked)
        XCTAssertFalse(g.bookGlow())
        while g.nextHezarfen() != nil {}
        let rep = g.state.rep
        if g.launch() != nil { _ = g.finishDay(flight: FlightResult(landing: .good, distance: 100)) }
        else { _ = g.finishDay(flight: nil) }
        XCTAssertEqual(g.state.local.glowCount, 1)
        XCTAssertNotNil(g.state.local.eveDay)
        XCTAssertGreaterThan(g.state.rep, rep)
        XCTAssertEqual(g.state.earned(.nightGlow), true)
        XCTAssertEqual(g.startNight(), .nightGlow(balloons: g.state.local.glowN ?? 0))
        XCTAssertGreaterThanOrEqual(g.state.local.glowN ?? 0, Glow.minBalloons)
        // Once per festival.
        if g.state.fiesta != nil { XCTAssertEqual(g.glowState, .done) }
    }

    func testEveningAscentIsHalfTheMorning() {
        var g = inBristol()
        g.state.cash = 100_000
        g.state.fiesta = Fiesta(start: g.state.day, end: g.state.day + 3)
        g.state.weather?.flag = .green
        g.state.demand = 1000
        while g.nextHezarfen() != nil {}
        XCTAssertNotNil(g.launch())
        let r = g.finishDay(flight: FlightResult(landing: .good, distance: 100))
        let pax = r.passengers, eve = jsRound(Double(min(8, pax)) * EveningAscent.pax)
        XCTAssertEqual(r.ledger.evening, eve * 185)
        XCTAssertTrue(r.events.contains(.eveningAscent(balloons: 1, pax: eve, income: eve * 185)))
    }

    func testFestivalEveryThirtyDaysFourDays() {
        var g = inBristol()
        var starts: [Int] = []
        for _ in 0..<80 {
            g.state.winter = nil
            g.state.nextWinter = g.state.day + 100
            play(&g)
            if let f = g.state.fiesta, f.start == g.state.day {
                starts.append(f.start)
                XCTAssertEqual(f.end - f.start + 1, 4)
            }
        }
        XCTAssertGreaterThanOrEqual(starts.count, 2)
        if starts.count >= 2 { XCTAssertEqual(starts[1] - starts[0], 4 + 30) }
        XCTAssertEqual(RegionID.bri.fiestaDemand, 1.8)
    }

    func testWorldGamesNeedsTheBristolBaron() {
        var g = newGame()
        g.state.barons[.cap] = 1
        g.state.holding.cash = 20_000_000
        XCTAssertFalse(g.holdWorldGamesShow())
        g.state.barons[.bri] = 5
        XCTAssertTrue(g.holdWorldGamesShow())
    }

    func testOldSavesDecodeWithoutBristolFields() throws {
        let g = inBristol()
        var data = try JSONEncoder().encode(g.state)
        var json = String(decoding: data, as: UTF8.self)
        for k in ["fogFlown", "glowCount"] { json = json.replacingOccurrences(of: "\"\(k)\":0,", with: "") }
        data = Data(json.utf8)
        let s = try JSONDecoder().decode(GameState.self, from: data)
        XCTAssertEqual(s.region, .bri)
        // An old Weather and Ledger without the new keys still decode.
        let w = #"{"flag":"green","surfaceWind":5,"layers":[1,2,3,4],"target":1500,"seed":3,"valley":800}"#
        XCTAssertNil(try JSONDecoder().decode(Weather.self, from: Data(w.utf8)).fog)
    }

    func testAchievementsAndPostcards() {
        var g = inBristol()
        XCTAssertTrue(g.state.earned(.bri))
        XCTAssertFalse(g.state.earned(.baronBri))
        g.state.barons[.bri] = g.state.day
        XCTAssertTrue(g.state.earned(.baronBri))
        g.checkAchievements()
        XCTAssertNotNil(g.state.postcards?[.bri])
    }
}
