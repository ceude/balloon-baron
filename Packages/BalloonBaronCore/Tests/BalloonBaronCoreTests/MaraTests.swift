import XCTest
@testable import BalloonBaronCore

/// Prototype v141: the Maasai Mara, the fifth and hardest region; the offices that open with their regions.
final class MaraTests: XCTestCase {
    func newGame(seed: UInt64 = 42) -> Game {
        var g = Game(company: "Test Air", colors: Rules.palettes[0], seed: seed)
        g.startDay()
        return g
    }

    /// Baron of every region up to Luxor, playing in Bristol with a full holding.
    func maraReady(seed: UInt64 = 42) -> Game {
        var g = newGame(seed: seed)
        g.state.barons[.cap] = 1
        g.grantStoreItem(.worldTour)
        g.state.holding.cash = 3_000_000
        XCTAssertTrue(g.enterRegion(.abq))
        g.state.barons[.abq] = g.state.day
        XCTAssertTrue(g.enterRegion(.lux))
        g.state.barons[.lux] = g.state.day
        XCTAssertTrue(g.enterRegion(.bri))
        return g
    }

    func inMara(seed: UInt64 = 42) -> Game {
        var g = maraReady(seed: seed)
        g.state.barons[.bri] = g.state.day
        XCTAssertTrue(g.enterRegion(.mara))
        return g
    }

    func testMaraOpensAfterBristolBaron() {
        var g = maraReady()
        XCTAssertEqual(RegionID.mara.unlockedBy, .bri)
        XCTAssertFalse(g.state.regionOpen(.mara))
        XCTAssertFalse(g.enterRegion(.mara), "Bristol's baron first")
        g.state.barons[.bri] = g.state.day
        XCTAssertTrue(g.state.regionOpen(.mara))
        let before = g.state.holding.cash
        g.state.hezQueue = []
        XCTAssertTrue(g.enterRegion(.mara))
        XCTAssertEqual(before - g.state.holding.cash, 300_000)
        XCTAssertEqual(g.state.region, .mara)
        XCTAssertEqual(g.state.cash, 6000)
        XCTAssertEqual(g.state.price, 210)
        XCTAssertEqual(g.state.demandBase, 125)
        XCTAssertEqual(g.state.local.rainsDone, 0)
        XCTAssertEqual(g.state.local.nextWinter, g.state.day + Mara.firstRains)
        XCTAssertEqual(g.state.local.fiestaNext, g.state.day + Mara.firstMigration)
        XCTAssertEqual(g.state.balloons.map(\.name), ["Talek"])
        XCTAssertEqual(g.state.rivals.map(\.name), ["Oloololo Sky Safaris", "Mara Dawn Balloons", "Talek Air"])
        XCTAssertEqual(g.state.bossRival?.name, "Oloololo Sky Safaris")
        XCTAssertEqual(Array(g.state.hezQueue.prefix(2)), [.enteredRegion(.mara), .guideHello(.mara)])
        XCTAssertEqual(g.state.region.entrants.map(\.name), ["Serengeti Crossing Balloons", "Budget Bush Flights", "Leopard Rock Luxury Flights", "Narok Highlands Balloons"])
        XCTAssertTrue(g.state.region.rivalEdge)
        XCTAssertTrue(g.state.region.mergesEarly)
        XCTAssertEqual(g.state.region.xlName, "Mara Yıldızı")
        XCTAssertEqual(MapPin.mara.region, .mara)
        XCTAssertFalse(MapPin.mara.mystery)
    }

    func testMaraIsPartOfTheGrandTour() {
        var g = newGame()
        for r in [RegionID.cap, .abq, .lux, .bri] { g.state.barons[r] = 1 }
        g.state.holding.cash = 1_000_000
        XCTAssertTrue(g.state.needsPack(.mara))
        XCTAssertFalse(g.enterRegion(.mara))
        g.grantStoreItem(.worldTour)
        XCTAssertFalse(g.state.needsPack(.mara))
        XCTAssertTrue(g.enterRegion(.mara))
    }

    func testDollarsToTheHolding() {
        XCTAssertEqual(RegionID.mara.currency, "USD")
        XCTAssertEqual(RegionID.mara.fx, RegionID.abq.fx)
        var g = inMara()
        g.state.cash = 44000
        let h = g.state.holding.cash
        let sent = g.withdraw(share: 1)
        XCTAssertEqual(sent, 34000, "the region keeps its reserve, as in Bristol")
        XCTAssertEqual(g.state.holding.cash - h, jsRound(34000 / 1.1), "dollars to euros at 1.1")
    }

    /// The hardest region: fewer tourists, a dearer start, the biggest rivals, dearer fuel and pilots, a park fee, worse
    /// weather and harder chapters than Bristol.
    func testHardestOfAllRegions() {
        let others: [RegionID] = [.cap, .abq, .lux, .bri]
        for r in others {
            XCTAssertLessThan(RegionID.mara.startDemand, r.startDemand)
            XCTAssertGreaterThanOrEqual(RegionID.mara.entryFee, r.entryFee)
            let fleet = { (x: RegionID) in x.startingRivals().reduce(0) { $0 + $1.balloons.reduce(0) { $0 + $1.capacity } } }
            XCTAssertGreaterThan(fleet(.mara), fleet(r), "the rivals' seats")
            XCTAssertLessThan(RegionID.mara.yellowTop - 0, 0.85 + 1e-9)
        }
        XCTAssertEqual(RegionID.mara.fuelFactor, 1.3)
        XCTAssertEqual(RegionID.mara.wageFactor, 1.1)
        XCTAssertLessThan(Mara.rainsGreen, 0.35, "the rains ground more mornings than any winter")
        XCTAssertGreaterThan(1 - Mara.rainsYellow, 1 - 0.7)
        XCTAssertLessThan(Mara.rainsDemand, 0.55)
        // the chapters ask more than Bristol's
        let b = RegionID.bri.chapters, m = RegionID.mara.chapters
        XCTAssertEqual(m.map(\.id), ["tentedCamp", "oloololo", "migration", "baronMara"])
        for (cb, cm) in zip(b, m) {
            let seats = { (c: Chapter) in c.goals.first { $0.kind == .seats }?.target ?? 0 }
            XCTAssertGreaterThanOrEqual(seats(cm), seats(cb))
        }
        XCTAssertTrue(m[1].goals.contains(Goal(kind: .rains, target: 1)))
        XCTAssertTrue(m[2].goals.contains(Goal(kind: .fiesta, target: 1)))
        XCTAssertTrue(m[3].goals.contains(Goal(kind: .stars, target: 4.85)))
        XCTAssertTrue(GoalKind.rains.yesNo)
    }

    func testParkFeeFuelAndWagesOnTheReport() {
        var g = inMara()
        g.state.day = 20
        g.state.cash = 100_000
        g.startDay()
        while g.nextHezarfen() != nil {}
        g.state.weather?.flag = .green
        guard g.launch() != nil else { return XCTFail("no flight") }
        let flying = g.state.plan?.flying ?? []
        let pax = flying.reduce(0) { $0 + (g.state.plan?.pax[$1] ?? 0) }
        let fuel = flying.compactMap(g.state.balloon).reduce(0) { $0 + jsRound(Double($1.size.fuel) * 1.3) }
        let r = g.finishDay(flight: FlightResult(landing: .good, distance: 120))
        XCTAssertGreaterThan(pax, 0)
        XCTAssertEqual(r.ledger.park, pax * Mara.parkFee)
        XCTAssertEqual(r.ledger.fuel, fuel)
        // the fee is part of the day's net
        var l = r.ledger; l.park = nil
        XCTAssertEqual(l.net - r.ledger.net, pax * Mara.parkFee)
        let p = Pilot.baseWage(.rookie, school: false, trait: nil, region: .mara), q = Pilot.baseWage(.rookie, school: false, trait: nil, region: .cap)
        XCTAssertEqual(Double(p), (Double(q) * 1.1).rounded(), accuracy: 1)
    }

    func testRainsTakeTurnsAndCountForTheChapter() {
        var g = inMara()
        g.state.cash = 100_000
        g.state.local.nextWinter = g.state.day
        g.maraRains()
        guard let w1 = g.state.winter else { return XCTFail("the long rains") }
        XCTAssertEqual(w1.long, true)
        XCTAssertEqual(w1.end - w1.start + 1, Mara.longRains)
        XCTAssertTrue(g.state.hezQueue.contains(.rainsComing(long: true, days: 12)))
        g.state.day = w1.end + 1
        g.maraRains()
        XCTAssertNil(g.state.winter)
        XCTAssertEqual(g.state.local.rainsDone, 1)
        XCTAssertEqual(g.state.value(.rains), 1)
        XCTAssertEqual(g.state.local.nextWinter, g.state.day + Mara.rainsEvery)
        g.state.day = g.state.local.nextWinter!
        g.maraRains()
        XCTAssertEqual(g.state.winter?.long, false)
        XCTAssertEqual(g.state.winter.map { $0.end - $0.start + 1 }, Mara.shortRains)
        // in the rains: half the tourists and mostly red mornings
        var red = 0
        for _ in 0..<2000 where g.rollFlag() == .red { red += 1 }
        XCTAssertGreaterThan(Double(red) / 2000, 0.36)
        // a newcomer with little cash is spared
        var h = inMara(seed: 7)
        h.state.cash = 5000
        h.state.local.nextWinter = h.state.day
        h.maraRains()
        XCTAssertNil(h.state.winter)
    }

    func testMigrationEveryFortyTwoDaysSixDays() {
        XCTAssertEqual(RegionID.mara.fiestaDays, 6)
        XCTAssertEqual(RegionID.mara.fiestaEvery, 36)
        XCTAssertEqual(RegionID.mara.fiestaDemand, 1.8)
        var g = inMara()
        g.state.local.nextWinter = 9999
        var started: [Int] = []
        for _ in 0..<120 {
            g.startDay()
            while g.nextHezarfen() != nil {}
            _ = g.launch(skip: true)
            _ = g.finishDay(flight: nil)
            if let f = g.state.fiesta, f.start == g.state.day { started.append(g.state.day); XCTAssertEqual(f.end - f.start + 1, 6) }
        }
        XCTAssertGreaterThanOrEqual(started.count, 2)
        if started.count > 1 { XCTAssertEqual(started[1] - started[0], 6 + 36) }
    }

    /// v131's rule holds in the Mara: every flyable day has an unobstructed layer toward the field, and a pilot who
    /// holds the best usable layer gets there without touching an acacia, a kopje, the river or a herd.
    func testWindReachesTheFieldOverTheSavanna() {
        let hold: [Double] = [30, 145, 265, 470]
        var flown = 0
        for seed in 0..<600 {
            var g = Game(company: "T", colors: ["#ffffff", "#000000"], seed: UInt64(seed) &* 7919 &+ 13)
            g.state.region = .mara
            g.state.day = 3 + seed % 400
            if seed % 3 == 0 { g.state.winter = Winter(start: g.state.day, end: g.state.day + 5, long: true) }
            let w = g.newWeather()
            XCTAssertGreaterThanOrEqual(w.target, 220 + 1350)
            XCTAssertLessThanOrEqual(w.target, 220 + 1850)
            XCTAssertGreaterThanOrEqual(FlightWorld.towardWind(w), Rules.minTowardWind, "\(w.flag) \(w.layers)")
            XCTAssertEqual(FlightWorld.usableLayers(w), [1, 2, 3], "no airspace in the Mara")
            guard w.flag != .red else { continue }
            let use = FlightWorld.usableLayers(w), i = use.max { w.layers[$0] < w.layers[$1] }!
            var f = FlightSim(weather: w, pax: 8, region: .mara, migration: seed % 2 == 0)
            XCTAssertTrue(f.lines.isEmpty, "no power lines on the savanna")
            var steps = 0
            while !f.done && f.x < w.target - 120 && steps < 30 * 600 {
                f.burning = f.alt + f.vy * 6 < hold[i]
                _ = f.step(1 / 30)
                steps += 1
            }
            XCTAssertFalse(f.done, "came down at x \(Int(f.x))")
            XCTAssertGreaterThanOrEqual(f.x, w.target - 120)
            flown += 1
        }
        XCTAssertGreaterThan(flown, 300)
    }

    func testTheWorldKeepsBothFieldsClear() {
        for seed in UInt64(1)...300 {
            let w = Weather(flag: .green, surfaceWind: 5, layers: [1, -2, 4, 3], target: 220 + 1350 + Double(seed % 50) * 10, seed: seed, mission: seed % 5 == 0 ? .valley : nil, valley: 900)
            let f = FlightSim(weather: w, pax: 4, region: .mara, migration: seed % 2 == 0)
            guard let m = f.mara else { return XCTFail("the Mara's world") }
            XCTAssertNil(FlightSim(weather: w, pax: 4).mara, "only in the Mara")
            if w.mission == .valley { XCTAssertEqual(m.river.map { ($0.x0 + $0.x1) / 2 }, 900, "the valley is the river") }
            for x in stride(from: w.target - 80, through: w.target + 80, by: 10) {
                XCTAssertFalse(m.inRiver(x), "the landing field is dry")
                for t in stride(from: 0.0, through: 900, by: 30) { XCTAssertNil(m.herd(at: x, time: t), "no herd ever wanders onto the field") }
            }
            for x in stride(from: 160.0, through: 280, by: 10) { XCTAssertFalse(m.inRiver(x)); XCTAssertNil(m.herd(at: x, time: 0)) }
            XCTAssertTrue(f.obstacles.allSatisfy { $0.kind == .acacia || $0.kind == .kopje })
            XCTAssertEqual(m.herds.count <= (seed % 2 == 0 ? 5 : 3), true)
            XCTAssertEqual(FlightSim(weather: w, pax: 4, region: .mara, migration: seed % 2 == 0).mara, m, "seeded")
        }
    }

    func testRiverIsADisasterAndHerdsAreFined() {
        // the river: whatever the touchdown, a crash
        var w = Weather(flag: .green, surfaceWind: 5, layers: [1, -2, 4, 3], target: 1800, seed: 9, mission: nil, valley: 900)
        var f = FlightSim(weather: w, pax: 4, region: .mara)
        guard let r = f.mara?.river else { return XCTFail("a river today") }
        f.x = (r.x0 + r.x1) / 2; f.airborne = true; f.alt = 0
        f.land(nil)
        XCTAssertEqual(f.result?.landing, .crash)
        XCTAssertEqual(f.result?.river, true)
        XCTAssertEqual(f.hit, .river)
        // a herd: the fine at the end of the day
        w.seed = 9
        var f2 = FlightSim(weather: w, pax: 4, region: .mara)
        if let h = f2.mara?.herds.first {
            f2.t = 0; f2.x = h.center(at: 0); f2.airborne = true; f2.alt = 0
            f2.land(nil)
            XCTAssertEqual(f2.result?.herd, h.kind)
        }
        var g = inMara()
        g.state.day = 20
        g.state.cash = 100_000
        g.startDay()
        while g.nextHezarfen() != nil {}
        g.state.weather?.flag = .green
        XCTAssertNotNil(g.launch())
        let rep = g.state.rep
        var res = FlightResult(landing: .good, distance: 120)
        res.herd = .elephant
        let rpt = g.finishDay(flight: res)
        XCTAssertEqual(rpt.ledger.fines, Mara.herdFine)
        XCTAssertTrue(rpt.events.contains(.herdLanding(.elephant, fine: Mara.herdFine)))
        XCTAssertTrue(g.state.reviews.contains { $0.kind == .herd })
        XCTAssertTrue((g.state.paperNext ?? []).contains(.herdLanding(fine: Mara.herdFine)))
        XCTAssertLessThan(g.state.rep, rep)
    }

    func testSafariPlaneContracts() {
        let K = RegionID.mara.contracts!
        XCTAssertEqual(K.kind, .bush)
        XCTAssertEqual(K.cast, [.grace, .rajesh, .peter])
        XCTAssertEqual(K.cast.map(\.company), ["Rift Valley Air Safaris", "Acacia Wings", "Kilima Air"])
        XCTAssertEqual(K.len, 2...3)
        XCTAssertEqual(K.delay?.after, 1)
        XCTAssertEqual(K.minSeats, 56)
        XCTAssertFalse(K.redMove)
        for seed in UInt64(1)...20 {
            var g = inMara(seed: seed)
            g.state.local.chapter = 1
            g.state.weather?.flag = .green
            for _ in 0..<5 { g.addBalloon(.L) }
            g.state.local.contracts = ContractState()
            g.state.local.contracts?.next = g.state.day
            g.contractMorning()
            guard let o = g.state.local.contracts?.offer else { return XCTFail("no offer (seed \(seed))") }
            XCTAssertEqual(o.owner, .grace, "the first owner calls first")
            XCTAssertTrue((2...3).contains(o.len))
            XCTAssertLessThanOrEqual(o.price, o.top)
            XCTAssertLessThanOrEqual(o.top, g.state.price)
        }
    }

    func testOfficesOpenWithTheirRegions() {
        XCTAssertNil(Office.ist.needs)
        XCTAssertNil(Office.sel.needs)
        XCTAssertEqual(Office.nyc.needs, .abq)
        XCTAssertEqual(Office.tyo.needs, .lux)
        XCTAssertEqual(Office.lon.needs, .bri)
        XCTAssertEqual(Office.dxb.needs, .mara)
        XCTAssertEqual(Office.lon.rawValue, "par", "an office bought as Paris is the London office")
        var g = newGame()
        g.state.barons[.cap] = 1
        g.grantStoreItem(.worldTour)
        g.state.holding.cash = 20_000_000
        for o in [Office.nyc, .tyo, .lon, .dxb] { XCTAssertFalse(g.openOffice(o), "\(o) needs its region") }
        XCTAssertTrue(g.openOffice(.ist))
        XCTAssertTrue(g.openOffice(.sel))
        XCTAssertTrue(g.enterRegion(.abq)); XCTAssertTrue(g.openOffice(.nyc))
        g.state.barons[.abq] = 1; XCTAssertTrue(g.enterRegion(.lux)); XCTAssertTrue(g.openOffice(.tyo))
        g.state.barons[.lux] = 1; XCTAssertTrue(g.enterRegion(.bri)); XCTAssertTrue(g.openOffice(.lon))
        XCTAssertFalse(g.openOffice(.dxb))
        g.state.barons[.bri] = 1; XCTAssertTrue(g.enterRegion(.mara)); XCTAssertTrue(g.openOffice(.dxb))
        XCTAssertEqual(g.state.holding.offices.count, 6)
        // the perks: Dubai lifts the Mara, Tokyo took Luxor's +20% (and keeps +5% everywhere), London lifts Bristol
        let h = g.state.holding, rd = h.researchAutopilot
        XCTAssertEqual(h.officeMultiplier(.mara), 1.2 * Holding.tokyoBoost * rd, accuracy: 1e-9)
        XCTAssertEqual(h.officeMultiplier(.lux), 1.2 * Holding.tokyoBoost * rd, accuracy: 1e-9)
        XCTAssertEqual(h.officeMultiplier(.bri), Holding.londonBoost * Holding.tokyoBoost * rd, accuracy: 1e-9)
        XCTAssertEqual(h.officeHere(.bri), Holding.londonBoost * Holding.tokyoBoost, accuracy: 1e-9)
        XCTAssertEqual(h.documentaryCost, jsRound(Double(Holding.documentaryCost) * 0.8))
    }

    /// An office bought before v141 stays open, whatever region it now needs.
    func testOfficesFromOldSavesStay() throws {
        var g = newGame()
        g.state.holding.offices = [.dxb: 300, .lon: 310]
        var data = try JSONEncoder().encode(g.state)
        let json = String(decoding: data, as: UTF8.self)
        XCTAssertTrue(json.contains("\"par\""), "London keeps the save key")
        data = Data(json.utf8)
        let s = try JSONDecoder().decode(GameState.self, from: data)
        XCTAssertNotNil(s.holding.offices[.lon])
        XCTAssertNotNil(s.holding.offices[.dxb])
        var h = Game(state: s, seed: 1)
        XCTAssertTrue(h.canOpenOffice(.dxb), "already open")
        XCTAssertFalse(h.openOffice(.dxb), "one each")
    }

    func testOldSavesDecodeWithoutMaraFields() throws {
        let g = inMara()
        var data = try JSONEncoder().encode(g.state)
        var json = String(decoding: data, as: UTF8.self)
        for k in ["rainsDone", "rainsCount"] { json = json.replacingOccurrences(of: "\"\(k)\":0,", with: "") }
        data = Data(json.utf8)
        let s = try JSONDecoder().decode(GameState.self, from: data)
        XCTAssertEqual(s.region, .mara)
        XCTAssertNil(s.local.rainsDone)
        // an old winter and an old ledger without the new keys still decode
        let w = try JSONDecoder().decode(Winter.self, from: Data(#"{"start":3,"end":10}"#.utf8))
        XCTAssertNil(w.long)
        let l = try JSONDecoder().decode(Ledger.self, from: try JSONEncoder().encode(Ledger()))
        XCTAssertNil(l.park)
        let r = try JSONDecoder().decode(FlightResult.self, from: Data(#"{"landing":"good","distance":10,"missionDone":false}"#.utf8))
        XCTAssertNil(r.herd)
    }

    func testAchievementsReviewsAndNights() {
        var g = inMara()
        XCTAssertTrue(g.state.earned(.mara))
        XCTAssertFalse(g.state.earned(.baronMara))
        g.state.barons[.mara] = g.state.day
        XCTAssertTrue(g.state.earned(.baronMara))
        XCTAssertEqual(Review.Kind.herd.variants, [2, 3])
        XCTAssertEqual(Review.Kind.river.variants, [1, 2])
        g.state.fiesta = Fiesta(start: g.state.day - 1, end: g.state.day + 3)
        XCTAssertEqual(g.startNight(), .migrationNight)
        g.state.fiesta = nil
        g.state.winter = Winter(start: g.state.day - 1, end: g.state.day + 5, long: false)
        XCTAssertEqual(g.startNight(), .rainNight)
        XCTAssertEqual(OutskirtsLayout.decorKinds(.mara).first, .savanna)
        XCTAssertTrue(OutskirtsLayout.decorKinds(.mara).contains(.manyatta))
    }
}
