import XCTest
@testable import BalloonBaronCore

/// v140 (developer, from the holding economy review in `tools/sim-holding.js`): new prices for the holding's campaigns,
/// deals and records, the offices' rent and better perks (Tokyo, Paris, R&D level 4), the World Games again every 360
/// days, the International Balloon Festival and the Hot Air Foundation.
final class Holding140Tests: XCTestCase {
    /// Cappadocia parked, playing in Albuquerque, a rich holding.
    func rich() -> Game {
        var g = Game(company: "Test Air", colors: Rules.palettes[0], seed: 42)
        g.state.tutorial = TutorialState(done: true)
        g.startDay()
        g.state.chapter = 4
        g.state.barons[.cap] = 1
        g.grantStoreItem(.worldTour)
        g.state.local.netHistory = [20000, 22000, 24000]
        g.state.holding.cash = 200_000
        XCTAssertTrue(g.enterRegion(.abq))
        g.state.holding.cash = 100_000_000
        g.state.hezQueue = []
        g.state.paperNext = nil
        return g
    }

    func reload(_ g: Game) throws -> Game {
        Game(state: try JSONDecoder().decode(GameState.self, from: JSONEncoder().encode(g.state)))
    }

    func rep(_ g: Game, _ r: RegionID) -> Double { r == g.state.region ? g.state.rep : g.state.parked[r]!.state.rep }

    func setRep(_ g: inout Game, _ r: RegionID, _ v: Double) {
        if r == g.state.region { g.state.rep = v } else { g.state.parked[r]!.state.rep = v }
    }

    // MARK: Prices

    func testCelebrityFirstDealStaysAGoalPrice() {
        var g = rich()
        XCTAssertEqual(g.state.holding.celebrityCost, 600_000, "the first deal, a holding goal, stays €600,000")
        XCTAssertTrue(g.signCelebrity())
        XCTAssertEqual(g.state.holding.celebrity?.until, g.state.day + 180)
        XCTAssertTrue(g.state.met(.celebrity))
        XCTAssertEqual(g.state.holding.celebrityCost, 1_800_000, "every deal after it")
        XCTAssertFalse(g.signCelebrity(), "one face at a time")
        XCTAssertEqual(g.holdingBoost(.cap), 1.1, accuracy: 1e-9)
        g.state.day += 180
        g.state.holding.offices[.sel] = g.state.day
        XCTAssertEqual(g.state.holding.celebrityCost, 1_350_000, "Seoul takes 25% off")
        XCTAssertEqual(g.state.holding.celebrityDays, 180, "and no longer doubles the length")
        let cash = g.state.holding.cash
        XCTAssertTrue(g.signCelebrity())
        XCTAssertEqual(g.state.holding.cash, cash - 1_350_000)
    }

    func testBillboardsJerseyDocumentaryAndRecords() {
        var g = rich()
        XCTAssertEqual([Holding.billboardCost, Holding.billboardDays], [80_000, 30])
        let cash = g.state.holding.cash, d = g.state.day
        XCTAssertTrue(g.runBillboards(in: .cap))
        XCTAssertEqual(g.state.holding.cash, cash - 80_000)
        XCTAssertEqual(g.state.holding.billboards[.cap], d + 30)
        XCTAssertEqual(g.holdingBoost(.cap), 1.08, accuracy: 1e-9)
        XCTAssertTrue(g.sponsorJersey())
        XCTAssertEqual(g.state.holding.cash, cash - 80_000 - 10_000_000)
        XCTAssertEqual(g.state.holding.jerseyUntil, d + 360)
        XCTAssertEqual(g.state.holding.documentaryCost, 3_000_000)
        g.state.holding.offices[.lon] = d
        XCTAssertEqual(g.state.holding.documentaryCost, 2_400_000, "Paris still takes 20% off")
        XCTAssertEqual(RecordAttempt.allCases.map(\.cost), [1_500_000, 4_000_000, 8_000_000])
        g.state.holding.offices[.dxb] = d
        XCTAssertEqual(RecordAttempt.allCases.map { g.state.holding.recordCost($0) }, [1_125_000, 3_000_000, 6_000_000], "Dubai 25% off")
    }

    func testResearchLevelFourLiftsParkedRegionsByFivePercent() {
        var h = Holding()
        h.research = 3
        XCTAssertEqual(h.researchAutopilot, 1.05, accuracy: 1e-9)
        h.research = 4
        XCTAssertEqual(h.researchAutopilot, 1.05 * 1.05, accuracy: 1e-9)
        XCTAssertEqual(h.fuelFactor, 0.75)
        XCTAssertEqual(h.upkeepFactor, 0.85)
    }

    // MARK: Offices

    func testOfficeRentIsADailyHoldingExpense() {
        var g = rich()
        XCTAssertEqual(Office.allCases.map(\.rent), [1000, 2000, 1500, 1500, 1500, 2000], "İstanbul, New York, Seoul, Tokyo, Dubai, London")
        XCTAssertEqual(Dictionary(uniqueKeysWithValues: Office.allCases.map { ($0, $0.rent) })[.lon], 2000)
        XCTAssertTrue(g.openOffice(.ist))
        XCTAssertTrue(g.openOffice(.nyc)) // v141: New York opens with Albuquerque, where this game plays
        XCTAssertEqual(g.state.holding.officeRent, 3000)
        g.state.parked[.cap]!.auto.todayRaw = 40_000
        let cash = g.state.holding.cash
        g.state.day += 1
        let net = g.holdingDay()
        let gross = g.state.holding.todayGross, cost = g.state.holding.todayCost
        XCTAssertGreaterThan(gross, 0)
        XCTAssertEqual(g.state.holding.todayRent, 3000)
        XCTAssertEqual(g.state.holding.cash, cash + gross - cost - 3000)
        XCTAssertEqual(net, gross - cost - 3000)
        XCTAssertEqual(g.state.holding.history.last?.expense, cost + 3000, "the rent is in the day's holding expenses")
        for o in Office.allCases { g.state.holding.offices[o] = 1 }
        XCTAssertEqual(g.state.holding.officeRent, 9500)
    }

    func testRentNeverTakesTheHoldingBelowZero() {
        var g = rich()
        for o in Office.allCases { g.state.holding.offices[o] = 1 }
        g.state.holding.cash = 2000
        g.state.parked[.cap]!.auto.todayRaw = 0
        g.state.day += 1
        _ = g.holdingDay()
        XCTAssertEqual(g.state.holding.cash, 0)
        XCTAssertEqual(g.state.holding.todayRent, 2000)
    }

    func testTokyoAndParisPerks() {
        var h = Holding()
        XCTAssertEqual(h.officeHere(.cap), 1)
        h.offices[.tyo] = 1
        for r in RegionID.allCases {
            XCTAssertEqual(h.officeHere(r), 1.05, accuracy: 1e-9, "Tokyo: +5% tourists in \(r) while you play there")
            XCTAssertEqual(h.officeMultiplier(r), r == .lux ? 1.05 * 1.2 : 1.05, accuracy: 1e-9, "and on its autopilot (v141: Luxor's +20% moved to Tokyo)")
        }
        h.offices[.lon] = 1
        XCTAssertEqual(h.officeHere(.bri), 1.05 * 1.2, accuracy: 1e-9, "London (was Paris): Bristol +20% also while you play there")
        XCTAssertEqual(h.officeMultiplier(.bri), 1.05 * 1.2, accuracy: 1e-9)
        XCTAssertEqual(h.officeHere(.lux), 1.05, accuracy: 1e-9)
        var g = rich()
        g.state.holding.offices[.tyo] = 1
        XCTAssertTrue(g.demandFactors.contains { $0.factor == .offices && abs($0.k - 1.05) < 1e-9 })
    }

    // MARK: World Games

    func testWorldGamesComeRoundEvery360DaysDearerEachTime() throws {
        var g = rich()
        g.state.barons[.bri] = 1
        let d = g.state.day
        XCTAssertEqual(g.state.holding.worldGamesPrice, 10_000_000, "the first show, a holding goal")
        var cash = g.state.holding.cash
        XCTAssertTrue(g.holdWorldGamesShow())
        XCTAssertEqual(g.state.holding.cash, cash - 10_000_000)
        XCTAssertEqual(g.state.holding.worldGamesHeld, 1)
        XCTAssertEqual(g.state.holding.worldGamesNext, d + 360)
        XCTAssertEqual(g.state.holding.worldGamesPrice, 15_000_000)
        g.state.day = d + 359
        XCTAssertFalse(g.canHoldWorldGames)
        XCTAssertFalse(g.holdWorldGamesShow())
        g.state.day = d + 360
        cash = g.state.holding.cash
        XCTAssertTrue(g.holdWorldGamesShow())
        XCTAssertEqual(g.state.holding.cash, cash - 15_000_000)
        XCTAssertEqual(g.state.holding.worldGamesUntil, d + 360 + Holding.worldGamesDays)
        XCTAssertEqual(g.state.holding.worldGamesPrice, 22_500_000)
        let back = try reload(g)
        XCTAssertEqual(back.state.holding.worldGamesHeld, 2)
        XCTAssertEqual(back.state.holding.worldGamesNext, d + 720)
    }

    func testAnOldSavesWorldGamesShowCountsAsTheFirst() throws {
        let json = #"{"cash":5,"history":[],"todayGross":0,"todayCost":0,"tvUntil":0,"tvCooldown":0,"billboards":{},"research":4,"offices":{},"worldGamesUntil":700}"#
        let h = try JSONDecoder().decode(Holding.self, from: Data(json.utf8))
        XCTAssertNil(h.worldGamesCount)
        XCTAssertEqual(h.worldGamesHeld, 1)
        XCTAssertEqual(h.worldGamesLast, 640, "held 60 days before its effect ended")
        XCTAssertEqual(h.worldGamesNext, 1000)
        XCTAssertEqual(h.worldGamesPrice, 15_000_000)
    }

    // MARK: International Balloon Festival

    func testFestivalCostCooldownAndEffects() throws {
        var g = rich()
        setRep(&g, .cap, 1.0)
        setRep(&g, .abq, 1.0)
        let d = g.state.day
        XCTAssertEqual(g.state.holding.festivalCost, 1_500_000)
        XCTAssertFalse(g.hostFestival(in: .lux), "only in a region you own")
        let cash = g.state.holding.cash
        XCTAssertTrue(g.hostFestival(in: .cap))
        XCTAssertEqual(g.state.holding.cash, cash - 1_500_000)
        XCTAssertEqual(g.state.holding.festival, Holding.HostedFestival(region: .cap, until: d + 10, next: d + 90, count: 1))
        XCTAssertEqual(g.holdingBoost(.cap), 1.4 * 1.03, accuracy: 1e-9, "+40% for ten days and +3% fame")
        XCTAssertEqual(g.holdingBoost(.abq), 1, accuracy: 1e-9, "only there")
        XCTAssertEqual(rep(g, .cap), 1.15, accuracy: 1e-9, "popularity there")
        XCTAssertEqual(rep(g, .abq), 1.0, accuracy: 1e-9)
        XCTAssertEqual(g.state.hezQueue.last, .festivalHosted(.cap))
        XCTAssertEqual(g.state.paperNext?.last, .festivalHosted(.cap))
        XCTAssertEqual(g.state.holding.festivalCost, 2_000_000, "each festival €500,000 more")
        XCTAssertFalse(g.hostFestival(in: .abq), "one at a time, every 90 days")
        g.state.day = d + 10
        XCTAssertEqual(g.holdingBoost(.cap), 1.03, accuracy: 1e-9, "the fame stays")
        g.state.day = d + 89
        XCTAssertFalse(g.canHostFestival(in: .abq))
        g.state.day = d + 90
        XCTAssertTrue(g.hostFestival(in: .abq))
        XCTAssertTrue(g.demandFactors.contains { $0.factor == .hostedFestival && abs($0.k - 1.4) < 1e-9 })
        XCTAssertTrue(g.demandFactors.contains { $0.factor == .festivalFame && abs($0.k - 1.03) < 1e-9 })
        let back = try reload(g)
        XCTAssertEqual(back.state.holding.festival, g.state.holding.festival)
        XCTAssertEqual(back.state.holding.festivalsIn, [.cap: 1, .abq: 1])
    }

    func testFestivalPriceAndFameAreCapped() {
        var g = rich()
        var prices: [Int] = []
        for i in 0..<9 {
            g.state.day += 90
            prices.append(g.state.holding.festivalCost)
            XCTAssertTrue(g.hostFestival(in: .cap), "festival \(i + 1)")
        }
        XCTAssertEqual(prices, [1_500_000, 2_000_000, 2_500_000, 3_000_000, 3_500_000, 4_000_000, 4_500_000, 5_000_000, 5_000_000])
        XCTAssertEqual(g.state.holding.festivalsIn?[.cap], 9)
        XCTAssertEqual(g.state.holding.festivalFame(.cap), 0.15, accuracy: 1e-9, "+3% a festival, at most +15%")
        g.state.day += 20
        XCTAssertEqual(g.holdingBoost(.cap), 1.15, accuracy: 1e-9)
    }

    func testFestivalNight() {
        var g = rich()
        XCTAssertTrue(g.hostFestival(in: .abq))
        g.state.day += 1
        XCTAssertEqual(g.startNight(), .festivalGlow)
    }

    // MARK: Hot Air Foundation

    func testFoundationProjectsCostMoreEachTimeAndLiftEveryRegion() throws {
        var g = rich()
        setRep(&g, .cap, 1.0)
        setRep(&g, .abq, 1.0)
        var cash = g.state.holding.cash
        XCTAssertEqual(g.state.holding.projectCost, 1_000_000)
        XCTAssertFalse(g.fundProject(in: .bri), "only in a region you own")
        XCTAssertTrue(g.fundProject(in: .cap))
        XCTAssertEqual(g.state.holding.cash, cash - 1_000_000)
        XCTAssertEqual(rep(g, .cap), 1.05, accuracy: 1e-9, "popularity in every region you own")
        XCTAssertEqual(rep(g, .abq), 1.05, accuracy: 1e-9)
        XCTAssertEqual(g.state.hezQueue.last, .foundationProject(.cap, 0))
        XCTAssertEqual(g.state.paperNext?.last, .foundationProject(.cap, 0, count: 1))
        XCTAssertEqual(g.state.holding.projectCost, 1_500_000)
        cash = g.state.holding.cash
        XCTAssertTrue(g.fundProject(in: .cap), "no wait between projects")
        XCTAssertTrue(g.fundProject(in: .abq))
        XCTAssertEqual(g.state.holding.cash, cash - 1_500_000 - 2_000_000)
        XCTAssertEqual(g.state.holding.projects, 3, "the foundation's legacy")
        XCTAssertEqual(g.state.holding.projects(in: .cap), 2, "two monuments' worth in Cappadocia's town")
        XCTAssertEqual(g.state.holding.lastProject, Holding.FundedProject(region: .abq, index: 0, day: g.state.day))
        XCTAssertEqual(g.state.hezQueue.last, .foundationProject(.abq, 0))
        XCTAssertEqual(rep(g, .cap), 1.15, accuracy: 1e-9)
        let back = try reload(g)
        XCTAssertEqual(back.state.holding.foundation, [.cap: 2, .abq: 1])
        XCTAssertEqual(back.state.holding.projectCost, 2_500_000)
    }

    func testFoundationPostcard() {
        var g = rich()
        XCTAssertFalse(g.state.earned(.patron))
        XCTAssertTrue(g.fundProject(in: .abq))
        XCTAssertTrue(g.state.earned(.patron))
        g.checkAchievements()
        XCTAssertTrue((g.state.newPostcards ?? []).contains(.patron))
    }

    // MARK: Saves

    /// A v139 holding, without any v140 key, decodes; the new keys come back after a save.
    func testOldHoldingDecodes() throws {
        let json = #"{"cash":5,"history":[],"todayGross":0,"todayCost":0,"tvUntil":0,"tvCooldown":0,"billboards":{},"research":2,"offices":{"ist":3,"tyo":4},"recordsV2":true}"#
        var h = try JSONDecoder().decode(Holding.self, from: Data(json.utf8))
        XCTAssertNil(h.festival)
        XCTAssertNil(h.festivalsIn)
        XCTAssertNil(h.foundation)
        XCTAssertNil(h.lastProject)
        XCTAssertNil(h.todayRent)
        XCTAssertNil(h.worldGamesCount)
        XCTAssertEqual(h.worldGamesHeld, 0)
        XCTAssertEqual(h.festivalCost, 1_500_000)
        XCTAssertEqual(h.projectCost, 1_000_000)
        XCTAssertEqual(h.officeRent, 2500)
        h.festival = Holding.HostedFestival(region: .cap, until: 10, next: 90, count: 1)
        h.festivalsIn = [.cap: 1]
        h.foundation = [.lux: 2]
        h.lastProject = Holding.FundedProject(region: .lux, index: 1, day: 9)
        h.worldGamesCount = 2
        h.worldGamesOn = 5
        h.todayRent = 2500
        let back = try JSONDecoder().decode(Holding.self, from: JSONEncoder().encode(h))
        XCTAssertEqual(back, h)
    }
}
