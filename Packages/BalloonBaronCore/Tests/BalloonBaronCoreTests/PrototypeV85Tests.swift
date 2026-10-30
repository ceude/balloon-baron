import XCTest
@testable import BalloonBaronCore

/// Rules ported from prototype v68–v85: buildings, traits, morning events, the paper, festivals, postcards, the store.
final class PrototypeV85Tests: XCTestCase {
    func newGame(seed: UInt64 = 42) -> Game {
        var g = Game(company: "Test Air", colors: Rules.palettes[0], seed: seed)
        g.startDay()
        return g
    }

    func play(_ g: inout Game, landing: FlightResult.Landing = .good) {
        g.startDay()
        while g.nextHezarfen() != nil {}
        if g.launch() != nil { g.finishDay(flight: FlightResult(landing: landing, distance: 120)) } else { g.finishDay(flight: nil) }
    }

    func testOpeningScheduleIsOneBuildingADay() {
        var g = newGame()
        var opened: [Feature: Int] = [:]
        for _ in 0..<12 {
            for f in Feature.allCases where g.state.unlocked.contains(f) && opened[f] == nil { opened[f] = g.state.day }
            g.state.cash = 3000 // stay below the €7.000 that opens the hangar early
            play(&g)
        }
        // v121.9: something opens every day from day 2 to day 11
        for (f, d) in Rules.unlockDay { XCTAssertEqual(opened[f], d, "\(f)") }
        XCTAssertEqual(Set(Rules.unlockDay.values).count, Rules.unlockDay.count, "one a day")
    }

    func testOldSaveKeepsWhatItsPagesBrought() {
        var g = newGame()
        g.state.day = 40
        g.state.unlocked = [.insurance, .fleet, .bank, .market, .crew]
        g.state.unlockVersion = nil
        g.state.hezQueue = []
        g.startDay()
        XCTAssertTrue(g.state.unlocked.isSuperset(of: [.guide, .agency, .bazaar, .workshop, .school]))
        for t in [Tip.guide, .agency, .workshop, .school] { XCTAssertFalse(g.state.hezQueue.contains(.tip(t)), "no burst of lessons") }
    }

    func testOldSaveWithoutNewFieldsLoads() throws {
        var g = newGame()
        play(&g)
        let data = try JSONEncoder().encode(g.state)
        var obj = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        for k in ["paperNext", "paper", "eventDue", "rescueShown", "bossSaid", "postcards", "newPostcards", "stats", "store"] { obj[k] = nil }
        var local = obj["local"] as! [String: Any]
        for k in ["buildings", "forecast", "festival", "festivalNext", "festivalCount", "bestPax", "strikeDay", "charter",
                  "fuelUpUntil", "docDay", "nextEvent", "lastEvent", "late", "lateChecked", "winterNight"] { local[k] = nil }
        obj["local"] = local
        obj["version"] = 2
        let old = try JSONSerialization.data(withJSONObject: obj)
        let back = try JSONDecoder().decode(GameState.self, from: old)
        XCTAssertEqual(back.day, g.state.day)
        XCTAssertEqual(back.level(.mast), 1)
        XCTAssertTrue(back.achievements.isEmpty)
    }

    func testUpgradesCostAndWork() {
        var g = newGame()
        g.state.cash = 200_000
        XCTAssertTrue(g.upgrade(.hangar))
        XCTAssertTrue(g.upgrade(.hangar))
        XCTAssertFalse(g.upgrade(.hangar), "three levels only")
        XCTAssertEqual(g.state.cash, 200_000 - 12000 - 45000)
        XCTAssertEqual(g.state.upkeepFactor, 0.7)
        XCTAssertEqual(g.state.topBuildingLevel, 3)
        g.launch(skip: true)
        let r = g.finishDay(flight: nil)
        XCTAssertEqual(r.ledger.upkeep, jsRound(Double(BalloonSize.S.upkeep) * 0.7))
        XCTAssertTrue(g.state.paper?.contains(.upgrade(.hangar, level: 3)) == true || g.state.paperNext?.contains(.upgrade(.hangar, level: 3)) == true)
    }

    func testForecastComesTrue() {
        var g = newGame()
        g.state.cash = 100_000
        g.upgrade(.mast)
        g.upgrade(.mast)
        let fc = g.forecast()
        XCTAssertEqual(fc.count, 2, "the radar shows tomorrow and the day after")
        play(&g)
        XCTAssertEqual(g.state.weather?.flag, fc[0])
        play(&g)
        XCTAssertEqual(g.state.weather?.flag, fc[1])
    }

    func testTraits() {
        var g = newGame()
        g.state.balloons.append(Balloon(id: 900, size: .M, name: "B"))
        g.state.pilots = [Pilot(id: 901, name: "P", level: .experienced, trait: .careful)]
        g.assignPilots()
        let b = g.state.balloon(900)!
        let careful = g.accidentChance(b)
        g.state.pilots[0].trait = .daredevil
        XCTAssertEqual(g.accidentChance(b) / careful, 1.3 / 0.75, accuracy: 1e-9)
        XCTAssertEqual(Pilot(id: 1, name: "O", level: .rookie, trait: .nightOwl).wage, jsRound(90 * 0.85))
    }

    func testCandidatesMostlyHaveTraits() {
        var g = newGame()
        var with = 0, all = 0
        for _ in 0..<40 { g.newCandidates(); all += g.state.candidates.count; with += g.state.candidates.filter { $0.trait != nil }.count }
        XCTAssertGreaterThan(Double(with) / Double(all), 0.6)
    }

    func testStrikeGroundsPilotsButNotTheFounder() {
        var g = newGame()
        g.state.balloons.append(Balloon(id: 900, size: .M, name: "B"))
        g.state.pilots = [Pilot(id: 901, name: "P", level: .experienced), Pilot(id: 902, name: "Q", level: .rookie)]
        g.assignPilots()
        XCTAssertEqual(g.answerEvent(.strike, accept: false), .strikeEndured)
        XCTAssertEqual(g.state.status(g.state.balloon(900)!), .strike)
        XCTAssertEqual(g.state.status(g.state.balloon(g.state.flagship)!), .ok)
        let wage = g.state.pilots[0].wage
        XCTAssertEqual(g.answerEvent(.strike, accept: true), .strikeRaised)
        XCTAssertEqual(g.state.pilots[0].wage, jsRound(Double(wage) * 1.15 / 5) * 5)
    }

    func testCharterAndDocumentaryTakeSeats() {
        var g = newGame()
        g.state.balloons.append(Balloon(id: 900, size: .M, name: "B"))
        g.state.pilots = [Pilot(id: 901, name: "P", level: .experienced)]
        g.assignPilots()
        let cash = g.state.cash, pay = g.eventOffer(.vip).pay
        XCTAssertGreaterThan(pay, 0)
        g.answerEvent(.vip, accept: true)
        XCTAssertEqual(g.state.cash, cash + pay)
        XCTAssertEqual(g.state.status(g.state.balloon(900)!), .chartered)
        g.answerEvent(.doc, accept: true)
        XCTAssertEqual(g.state.sellSeats(g.state.balloon(g.state.flagship)!), 4, "an 8-seat basket keeps 4 for the crew")
        XCTAssertEqual(g.state.capacityToday, 4)
    }

    func testPaperLeadsWithTheBiggestStory() {
        var g = newGame()
        g.addPaper(.upgrade(.mast, level: 2))
        g.addPaper(.rivalBankrupt(rival: "X", balloons: 3))
        g.addPaper(.vip)
        g.addPaper(.record(pax: 40))
        g.printPaper()
        XCTAssertEqual(g.readPaper(), [.rivalBankrupt(rival: "X", balloons: 3), .vip, .record(pax: 40)])
        XCTAssertNil(g.state.paper)
    }

    func testFestivalStartsOnDay24AndPaysMore() {
        var g = newGame()
        while g.state.day < 24 { g.state.cash = 3000; play(&g) }
        XCTAssertNotNil(g.state.festival)
        XCTAssertTrue(g.state.hezQueue.contains(.festivalStarted(0)) || g.state.festival?.index == 0)
        XCTAssertEqual(g.missionReward(.proposal, .S), 680) // 450 × 1.5, rounded to 10 (v124.6)
        if g.state.weather?.flag != .red { XCTAssertNotNil(g.state.weather?.mission, "festivals always bring a special request") }
    }

    func testMorningEventsComeEveryWeek() {
        var g = newGame()
        var events = 0
        for _ in 0..<40 {
            g.state.cash = max(g.state.cash, 3000)
            g.startDay()
            if g.state.eventDue == true, let e = g.drawMorningEvent() { events += 1; g.answerEvent(e, accept: false) }
            play(&g)
        }
        XCTAssertGreaterThanOrEqual(events, 2)
    }

    func testPostcardsAndStats() {
        var g = newGame()
        play(&g, landing: .perfect)
        XCTAssertNotNil(g.state.achievements[.first])
        XCTAssertEqual(g.nextPostcard(), .first)
        XCTAssertEqual(g.state.statistics.perfectLandings, 1)
        XCTAssertGreaterThan(g.state.statistics.passengers, 0)
    }

    func testBazaarPatternArrivesOnTheFlagship() {
        var g = newGame()
        g.grantStoreItem(.heart)
        let d = g.state.design(of: g.state.balloon(g.state.flagship)!)
        XCTAssertEqual(d?.shape, .heart)
        XCTAssertEqual(d?.gift, .heart)
        XCTAssertEqual(g.freshness(d!), 1, "paid designs never fade")
        XCTAssertEqual(g.paintCost(d!.id), 0)
        if case .bazaarGift(.heart, _) = g.state.hezQueue.first {} else { XCTFail("Hezarfen tells you") }
        g.grantStoreItem(.fountain)
        XCTAssertEqual(g.state.decorationCount, 1)
    }

    /// The Hezarfen balloon left the bazaar for the skull: a save that bought it owns the skull, and its design flies it.
    func testHezarfenBalloonSavesBecomeTheSkull() throws {
        var g = newGame()
        g.grantStoreItem(.skull)
        var json = String(decoding: try JSONEncoder().encode(g.state), as: UTF8.self)
        json = json.replacingOccurrences(of: "\"skull\"", with: "\"hezarfen\"")
        XCTAssertTrue(json.contains("hezarfen"))
        let old = try JSONDecoder().decode(GameState.self, from: Data(json.utf8))
        XCTAssertNotNil(old.store?[.skull])
        XCTAssertEqual(old.design(of: old.balloon(old.flagship)!)?.shape, .skull)
        XCTAssertEqual(StoreItem.skull.rawValue, "skull")
        XCTAssertEqual(StoreItem.allCases.count, 25)
    }

    /// Hezarfen praises good early moves: each once, at most every other day, never after day 40.
    func testPraiseComesEarlyOnceEachEveryOtherDay() {
        var g = newGame()
        var given: [(Int, Praise)] = []
        for _ in 0..<60 {
            g.startDay()
            while let m = g.nextHezarfen() { if case .praise(let p) = m { given.append((g.state.day, p)) } }
            if g.launch(skip: g.state.weather?.flag == .red) != nil { g.finishDay(flight: FlightResult(landing: .perfect, distance: 60)) } else { g.finishDay(flight: nil) }
        }
        XCTAssertTrue(given.contains { $0.1 == .perfect }, "a perfect landing is praised")
        XCTAssertEqual(Set(given.map(\.1)).count, given.count, "each praise once")
        XCTAssertTrue(given.allSatisfy { $0.0 <= 41 })
        for (a, b) in zip(given, given.dropFirst()) { XCTAssertGreaterThanOrEqual(b.0 - a.0, 2) }
    }

    func testNoRedFlagInTheFirstThreeDays() {
        for seed in 1...40 {
            var g = newGame(seed: UInt64(seed))
            for _ in 0..<3 {
                XCTAssertNotEqual(g.state.weather?.flag, .red)
                play(&g)
            }
        }
    }

    func testBossSaysHelloOnce() {
        var g = newGame()
        for _ in 0..<4 { play(&g) }
        let hellos = g.state.bossSaid?.filter { $0 == "cap.hello" }.count
        XCTAssertEqual(hellos, 1)
    }

    func testFlightMomentsAreDeterministic() {
        let w = Weather(flag: .green, surfaceWind: 5, layers: [1, 4, -2, 5], target: 1800, seed: 99, mission: nil, valley: 900)
        XCTAssertEqual(FlightSim(weather: w, pax: 8).moment, FlightSim(weather: w, pax: 8).moment)
        var hits = 0
        for s in 0..<100 as Range<UInt64> {
            var ww = w; ww.seed = s
            if let m = FlightSim(weather: ww, pax: 8).moment { hits += 1; XCTAssertGreaterThan(m.x, FlightWorld.launchX) }
        }
        XCTAssertGreaterThan(hits, 55)
        XCTAssertLessThan(hits, 85)
    }

    func testHoldingGoalsMakeWorldBaron() {
        var g = newGame()
        g.state.barons = [.cap: 1, .abq: 2, .lux: 3]
        g.state.holding.cash = 2_000_000
        g.state.holding.tvCount = 1
        g.state.holding.celebrity = Celebrity(index: 0, until: 100)
        g.state.holding.research = 2
        for o in Office.allCases { g.state.holding.offices[o] = 1 }
        g.checkHoldingGoals()
        XCTAssertNil(g.state.holding.worldBaron, "v123.5: the World Games show is the seventh goal")
        XCTAssertFalse(g.holdWorldGamesShow(), "the show needs the Baron of Bristol")
        XCTAssertFalse(g.state.worldGamesOpen)
        g.state.holding.worldGamesUntil = 60 // held (Bristol isn't in the Swift game yet)
        g.checkHoldingGoals()
        XCTAssertNotNil(g.state.holding.worldBaron)
        XCTAssertTrue(g.state.hezQueue.contains(.worldBaron))
    }

    func testOldWorldBaronKeepsTheWorldGamesGoal() {
        var g = newGame()
        g.state.holding.worldBaron = 300 // a save from before v123.5, World Baron with six goals
        XCTAssertTrue(HoldingGoal.allCases.allSatisfy(g.state.done))
    }
}
