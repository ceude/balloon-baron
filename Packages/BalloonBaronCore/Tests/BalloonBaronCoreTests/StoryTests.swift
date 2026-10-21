import XCTest
@testable import BalloonBaronCore

/// What came after v67: the paper, bosses, morning events, buildings, traits, achievements, the bazaar and the night.
final class StoryTests: XCTestCase {
    func newGame(seed: UInt64 = 7) -> Game {
        var g = Game(company: "Test Air", colors: Rules.palettes[0], seed: seed)
        g.startDay()
        return g
    }

    @discardableResult
    func play(_ g: inout Game, flight: FlightResult = FlightResult(landing: .good, distance: 80)) -> DayReport {
        g.beginMorning()
        while g.nextHezarfen() != nil {}
        if g.launch(skip: false) != nil { return g.finishDay(flight: flight) }
        return g.finishDay(flight: nil)
    }

    func greenDay(_ g: inout Game) {
        g.state.weather?.flag = .green
        g.state.weather?.mission = nil
    }

    // MARK: Saves

    func testOldSaveWithoutNewFieldsStillLoads() throws {
        var g = newGame()
        g.state.cash = 12345
        var json = try JSONSerialization.jsonObject(with: JSONEncoder().encode(g.state)) as! [String: Any]
        var local = json["local"] as! [String: Any]
        for k in local.keys where k.hasSuffix("Store") { local.removeValue(forKey: k) }
        json["local"] = local
        for k in json.keys where k.hasSuffix("Store") { json.removeValue(forKey: k) }
        // v67 stored flights and xp as whole numbers.
        var bs = local["balloons"] as! [[String: Any]]
        bs[0]["flights"] = 3
        local["balloons"] = bs
        json["local"] = local
        let data = try JSONSerialization.data(withJSONObject: json)
        let back = try JSONDecoder().decode(GameState.self, from: data)
        XCTAssertEqual(back.cash, 12345)
        XCTAssertEqual(back.local.balloons[0].flights, 3)
        XCTAssertEqual(back.level(.mast), 1)
        XCTAssertTrue(back.paper.isEmpty)
        XCTAssertEqual(back.local.festivalNext, Festival.firstDay)
    }

    // MARK: Unlocks and lessons

    func testBuildingsOpenEveryTwoDays() {
        var g = newGame()
        for day in 1...11 {
            g.state.day = day
            g.state.cash = 3000
            g.unlockCheck()
            let u = g.state.unlocked
            XCTAssertEqual(u.contains(.fleet), day >= 4, "fleet on day \(day)")
            XCTAssertEqual(u.contains(.bank), day >= 6)
            XCTAssertEqual(u.contains(.market), day >= 8)
            XCTAssertEqual(u.contains(.crew), day >= 10)
        }
        XCTAssertTrue(g.state.hezQueue.contains(.tip(.bazaar)))
        XCTAssertTrue(g.state.hezQueue.contains(.boss(.cap, .hello)))
    }

    // MARK: Paper

    func testPaperComesOutTheMorningAfterAndLeadsWithTheBiggestStory() {
        var g = newGame()
        g.state.cash = 100000
        g.paperAdd(1, .upgrade(.mast, level: 2))
        g.paperAdd(6, .rivalBankrupt(rival: "X", balloons: 3))
        g.paperAdd(3, .vip)
        g.paperAdd(2, .wedding)
        XCTAssertTrue(g.todaysPaper.isEmpty, "not until the next morning")
        g.beginMorning()
        XCTAssertEqual(g.todaysPaper.map(\.priority), [6, 3, 2])
        g.foldPaper()
        XCTAssertTrue(g.todaysPaper.isEmpty)
    }

    func testRecordDayMakesTheNews() {
        var g = newGame()
        g.state.day = 10
        g.state.local.bestPax = 8
        g.state.cash = 500000
        for _ in 0..<3 { g.buyBalloon(.L) }
        g.state.pilots = (0..<3).map { Pilot(id: 800 + $0, name: "P\($0)", level: .senior) }
        g.assignPilots()
        g.state.demand = 400
        greenDay(&g)
        let r = g.finishDayAfterLaunch()
        if r.passengers >= 16 { XCTAssertTrue(g.state.paperNext.contains { if case .record = $0.story { true } else { false } }) }
        XCTAssertEqual(g.state.local.bestPax, max(8, r.passengers))
    }

    // MARK: Bosses

    func testBossSpeaksOncePerLine() {
        var g = newGame()
        g.bossSay(.hello)
        g.bossSay(.hello)
        XCTAssertEqual(g.state.hezQueue.filter { $0 == .boss(.cap, .hello) }.count, 1)
        XCTAssertEqual(g.bossRival?.name, "Göreme Sky")
    }

    // MARK: Morning events

    func testEventsAreScheduledAboutWeekly() {
        var g = newGame()
        g.state.unlocked = Set(Feature.allCases)
        var days: [Int] = []
        for _ in 0..<40 {
            play(&g)
            if g.state.eventDue { days.append(g.state.day); _ = g.drawMorningEvent() }
        }
        XCTAssertEqual(days.first, MorningEvent.firstDay)
        for (a, b) in zip(days, days.dropFirst()) { XCTAssertTrue((7...8).contains(b - a), "gap \(b - a)") }
    }

    func testStrikeGroundsPilotsButYouFlyTheFlagship() {
        var g = newGame()
        g.state.cash = 100000
        g.buyBalloon(.M)
        g.state.pilots = [Pilot(id: 900, name: "A", level: .rookie), Pilot(id: 901, name: "B", level: .rookie)]
        g.state.selfFly = false
        g.assignPilots()
        XCTAssertEqual(g.resolveEvent(.strike, accept: false), .holdOut)
        XCTAssertTrue(g.state.selfFly)
        XCTAssertEqual(g.state.flyingToday.map(\.id), [g.state.flagship])
        XCTAssertTrue(g.state.balloons.contains { g.state.status($0) == .strike })
    }

    func testStrikeRaiseQuotesWhatItCosts() {
        var g = newGame()
        g.state.pilots = [Pilot(id: 900, name: "A", level: .rookie), Pilot(id: 901, name: "B", level: .experienced)]
        let before = g.wageBill, extra = g.strikeRaise
        g.resolveEvent(.strike, accept: true)
        XCTAssertEqual(g.wageBill, before + extra)
    }

    func testCharterTakesTheBalloonAndPaysUpFront() {
        var g = newGame()
        g.state.cash = 100000
        g.buyBalloon(.L)
        g.state.pilots = [Pilot(id: 900, name: "A", level: .rookie)]
        g.assignPilots()
        let o = g.charterOffer(.vip)!
        let cash = g.state.cash, seats = g.state.capacityToday
        XCTAssertEqual(g.resolveEvent(.vip, accept: true), .accepted)
        XCTAssertEqual(g.state.cash, cash + o.pay)
        XCTAssertEqual(g.state.status(o.balloon), .charter)
        XCTAssertEqual(g.state.capacityToday, seats - o.balloon.size.capacity)
    }

    func testDocumentaryTakesFourSeats() {
        var g = newGame()
        greenDay(&g)
        let seats = g.state.capacityToday
        g.resolveEvent(.doc, accept: true)
        XCTAssertEqual(g.state.capacityToday, seats - 4)
        g.state.demand = 300
        let pax = g.launch()
        XCTAssertLessThanOrEqual(pax ?? 0, 4)
    }

    func testPropaneRiseCostsHalfAgain() {
        var g = newGame()
        greenDay(&g)
        g.resolveEvent(.fuel, accept: false)
        let r = g.finishDayAfterLaunch()
        XCTAssertEqual(r.ledger.fuel, jsRound(Double(BalloonSize.S.fuel) * 1.5))
    }

    // MARK: Buildings

    func testUpgradesCostAndWork() {
        var g = newGame()
        g.state.cash = 100000
        XCTAssertNil(g.state.forecastFlag(for: g.state.day + 1), "no forecast before the weather station")
        XCTAssertTrue(g.upgrade(.mast))
        XCTAssertEqual(g.state.cash, 94000)
        let tomorrow = g.state.forecastFlag(for: g.state.day + 1)
        XCTAssertNotNil(tomorrow)
        XCTAssertNil(g.state.forecastFlag(for: g.state.day + 2), "the day after needs the radar")
        greenDay(&g)
        _ = g.finishDayAfterLaunch()
        XCTAssertEqual(g.state.weather?.flag, tomorrow, "the forecast comes true")
        XCTAssertTrue(g.upgrade(.mast))
        XCTAssertFalse(g.upgrade(.mast), "level 3 is the top")
        XCTAssertNotNil(g.state.forecastFlag(for: g.state.day + 2))
        XCTAssertTrue(g.state.paperNext.contains { $0.story == .upgrade(.mast, level: 3) })
    }

    func testHangarCutsUpkeepAndWear() {
        var g = newGame()
        g.state.cash = 200000
        g.upgrade(.hangar); g.upgrade(.hangar)
        greenDay(&g)
        let r = g.finishDayAfterLaunch()
        XCTAssertEqual(r.ledger.upkeep, jsRound(Double(BalloonSize.S.upkeep) * 0.7))
        XCTAssertEqual(g.state.balloons[0].flights, 0.85, accuracy: 1e-9)
    }

    // MARK: Traits

    func testTraits() {
        var careful = Pilot(id: 1, name: "C", level: .experienced)
        careful.trait = .careful
        var owl = Pilot(id: 2, name: "O", level: .experienced)
        owl.trait = .nightowl
        XCTAssertEqual(owl.wage, jsRound(150 * 0.85))
        var g = newGame()
        g.state.cash = 100000
        g.buyBalloon(.M)
        g.state.selfFly = false
        g.state.pilots = [careful]
        g.assignPilots()
        let b = g.state.balloons.first { $0.pilot == 1 }!
        let base = g.state.weather!.flag.accident * PilotLevel.experienced.risk * b.size.risk
        XCTAssertEqual(g.accidentChance(b), base * 0.75, accuracy: 1e-12)
        g.state.pilots[0].trait = .loyal
        for _ in 0..<200 { g.state.poach = nil; _ = g.finishDayAfterLaunch(); XCTAssertNil(g.state.poach, "loyal pilots are never poached") }
    }

    func testMostCandidatesHaveATrait() {
        var g = newGame()
        var n = 0, with = 0
        for _ in 0..<100 { g.newCandidates(); n += g.state.candidates.count; with += g.state.candidates.filter { $0.trait != nil }.count }
        XCTAssertEqual(Double(with) / Double(n), 0.75, accuracy: 0.08)
    }

    // MARK: Flight moments

    func testMomentsHappenOnMostFlightsAndPayTips() {
        var n = 0
        for seed: UInt64 in 0..<200 {
            var w = newGame(seed: seed).state.weather!
            w.seed = seed &* 7919
            if FlightSim(weather: w, pax: 8).moment != nil { n += 1 }
        }
        XCTAssertEqual(Double(n) / 200, 0.7, accuracy: 0.1)
        var g = newGame()
        greenDay(&g)
        g.state.demand = 300
        let pax = g.launch()!
        let r = g.finishDay(flight: FlightResult(landing: .good, distance: 80, moment: .photo))
        XCTAssertTrue(r.events.contains(.moment(.photo, tips: pax * 5)))
        XCTAssertEqual(r.ledger.tips, pax * 5 + pax * 6)
    }

    func testThermalLiftsYouAndGivesFuel() {
        var g = newGame()
        var w = g.state.weather!
        w.layers = [0, 0, 0, 0]
        w.flag = .green
        var f = FlightSim(weather: w, pax: 8)
        f.moment = MomentState(kind: .thermal, x: FlightWorld.launchX, alt: 0, colorIndex: 0)
        f.airborne = true
        f.alt = 100
        f.fuel = 50
        var done = false
        for _ in 0..<200 where !done { done = f.step(0.05).contains(.momentDone(.thermal)) }
        XCTAssertTrue(done)
        XCTAssertGreaterThan(f.fuel, 50)
        g.state.cash = 0
    }

    // MARK: Festivals

    func testFestivalsComeEveryFiveWeeksInCappadocia() {
        var g = newGame()
        var starts: [Int] = []
        for _ in 0..<100 {
            play(&g)
            if let f = g.state.local.festival, f.start == g.state.day { starts.append(f.start) }
            if g.state.winter != nil { g.state.winter = nil; g.state.local.nextWinter = 999 }
        }
        XCTAssertEqual(starts, [24, 59, 94])
        XCTAssertEqual(g.state.local.festivalCount, 3)
    }

    // MARK: Achievements and holding goals

    func testAchievementsBecomePostcards() {
        var g = newGame()
        play(&g)
        XCTAssertNotNil(g.state.achievements[.first])
        XCTAssertEqual(g.nextPostcard(), .first)
        XCTAssertNil(g.nextPostcard())
    }

    func testWorldBaron() {
        var g = newGame()
        g.state.barons = [.cap: 1, .abq: 2]
        g.state.holding.cash = 2_000_000
        g.state.holding.tvCount = 1
        g.state.holding.celebrity = Celebrity(index: 0, until: 0)
        g.state.holding.research = 2
        for o in Office.allCases { g.state.holding.offices[o] = 1 }
        g.checkHoldGoals()
        XCTAssertNotNil(g.state.worldBaron)
        XCTAssertTrue(g.state.hezQueue.contains(.worldBaron))
        XCTAssertNotNil(g.state.achievements[.world])
    }

    // MARK: Bazaar

    func testBoughtShapeArrivesAsAFreeDesignThatNeverFades() {
        var g = newGame()
        g.state.cash = 10000
        XCTAssertTrue(g.receive(.heart))
        let d = g.state.designs[0]
        XCTAssertEqual(d.shape, .heart)
        XCTAssertEqual(d.item, .heart)
        XCTAssertEqual(g.state.balloons[0].design, d.id, "the flagship wears it")
        XCTAssertEqual(g.paintCost(d.id), 0)
        g.state.day += 200
        XCTAssertEqual(g.freshness(d), 1)
        XCTAssertGreaterThan(g.designScore(pattern: .stripes, colors: d.colors, shape: .heart), g.designScore(pattern: .stripes, colors: d.colors))
        XCTAssertFalse(g.receive(.heart), "once")
    }

    func testDecorationsBringTourists() {
        var a = newGame(seed: 3), b = newGame(seed: 3)
        for i in ShopItem.decor { b.receive(i) }
        XCTAssertEqual(b.state.decorCount, 4)
        let da = a.dayDemand(), db = b.dayDemand()
        XCTAssertEqual(Double(db) / Double(da), 1.04, accuracy: 0.01)
    }

    func testPremiumPatternNeedsBuying() {
        var g = newGame()
        g.state.cash = 200000
        g.buildWorkshop()
        XCTAssertNil(g.createDesign(name: "", pattern: .gold, colors: ["#ff5e3a", "#ffc23d", "#ffffff"]))
        g.receive(.gold)
        XCTAssertNotNil(g.createDesign(name: "", pattern: .gold, colors: ["#ff5e3a", "#ffc23d", "#ffffff"]))
    }

    func testAdDoublesTheChapterRewardOnce() {
        var g = newGame()
        let news = ChapterNews(region: .cap, index: 0)
        let cash = g.state.cash
        XCTAssertEqual(g.claimAdBonus(news), 5000)
        XCTAssertEqual(g.claimAdBonus(news), 0)
        XCTAssertEqual(g.state.cash, cash + 5000)
    }

    // MARK: Rescue and night

    func testRescuePlan() {
        var g = newGame()
        g.state.cash = 100000
        g.buyBalloon(.M)
        g.buyBalloon(.S)
        g.state.pilots = (0..<4).map { Pilot(id: 900 + $0, name: "P", level: .rookie) }
        g.assignPilots()
        g.state.cash = -2000
        XCTAssertTrue(g.rescueDue)
        g.markRescueShown()
        XCTAssertFalse(g.rescueDue)
        XCTAssertEqual(g.rescueSale?.size, .S)
        g.fireIdlePilots()
        XCTAssertTrue(g.state.idlePilots.isEmpty)
        g.state.cash = 10
        g.checkRescued()
        XCTAssertEqual(g.state.hezQueue.first, .rescued)
        XCTAssertFalse(g.state.rescueShown)
    }

    func testNightEventsGoInTheMorningPaper() {
        var g = newGame()
        g.state.local.festival = Festival.Running(kind: .lights, start: g.state.day, end: g.state.day + 2)
        XCTAssertEqual(g.startNight(), .lanterns(.lights))
        g.state.local.festival = nil
        g.state.winter = Winter(start: 40, end: 47)
        XCTAssertEqual(g.startNight(), .snow)
        XCTAssertNotEqual(g.startNight(), .snow, "only the first winter night")
        g.beginMorning()
        XCTAssertTrue(g.todaysPaper.contains { $0.story == .night(.lanterns(.lights)) })
    }
}

extension Game {
    /// Launches with today's fleet and finishes the day with an ordinary landing.
    mutating func finishDayAfterLaunch() -> DayReport {
        if launch() != nil { return finishDay(flight: FlightResult(landing: .good, distance: 80)) }
        return finishDay(flight: nil)
    }
}
