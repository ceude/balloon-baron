import XCTest
@testable import BalloonBaronCore

/// v137 (TestFlight: "€18M in the holding and nothing left to spend it on"): the documentary series, R&D levels 3 and 4,
/// the Pacific crossing, the Dubai and Paris offices; the developer's new expense rule (any four offices 20%, all six
/// 15%) and holding goals (six offices, all four R&D levels), with old World Barons checked again on load.
final class Invest137Tests: XCTestCase {
    /// Cappadocia and Albuquerque owned (Cappadocia parked), Luxor open for records, a rich holding.
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
        g.state.holding.cash = 30_000_000
        g.state.hezQueue = []
        return g
    }

    func reload(_ g: Game) throws -> Game {
        Game(state: try JSONDecoder().decode(GameState.self, from: JSONEncoder().encode(g.state)))
    }

    // MARK: Documentary

    func testDocumentarySeason() throws {
        var g = rich()
        let cash = g.state.holding.cash, d = g.state.day
        let repHere = g.state.rep, repCap = g.state.parked[.cap]!.state.rep
        XCTAssertEqual(g.state.holding.documentaryCost, 3_000_000, "v140: €3M")
        XCTAssertTrue(g.makeDocumentary())
        XCTAssertEqual(g.state.holding.cash, cash - 3_000_000)
        XCTAssertEqual(g.state.holding.documentary, Holding.Documentary(until: d + 120, next: d + 180, season: 1))
        XCTAssertEqual(g.holdingBoost(.abq), 1.15, accuracy: 1e-9)
        XCTAssertEqual(g.holdingBoost(.cap), 1.15, accuracy: 1e-9, "every region")
        XCTAssertEqual(g.state.rep, min(1.4, repHere + 0.1), accuracy: 1e-9)
        XCTAssertEqual(g.state.parked[.cap]!.state.rep, min(1.4, repCap + 0.1), accuracy: 1e-9, "every region you own")
        XCTAssertTrue(g.state.hezQueue.contains(.deed(.documentary)))
        // on air, then a 60-day gap
        XCTAssertFalse(g.makeDocumentary())
        g.state.day = d + 150
        XCTAssertEqual(g.holdingBoost(.abq), 1, accuracy: 1e-9)
        XCTAssertFalse(g.canMakeDocumentary)
        g.state.day = d + 180
        XCTAssertTrue(g.canMakeDocumentary)
        // Paris takes a fifth off
        g.state.holding.offices[.lon] = d
        XCTAssertEqual(g.state.holding.documentaryCost, 2_400_000)
        XCTAssertTrue(g.makeDocumentary())
        XCTAssertEqual(g.state.holding.documentary?.season, 2)
        let back = try reload(g)
        XCTAssertEqual(back.state.holding.documentary, g.state.holding.documentary)
    }

    // MARK: R&D

    func testResearchLevelsThreeAndFour() throws {
        var g = rich()
        g.state.hezQueue = []
        XCTAssertTrue(g.fundResearch())
        XCTAssertTrue(g.fundResearch())
        XCTAssertEqual(g.state.envelopeLife, 200)
        XCTAssertFalse(g.state.met(.research), "v137: the goal wants all four levels")
        g.addBalloon(.L)
        let b = g.state.balloons.last!
        let risk0 = g.accidentChance(b), prem0 = g.premium(.L, chance: risk0)
        let cash = g.state.holding.cash
        XCTAssertTrue(g.fundResearch())
        XCTAssertEqual(g.state.holding.cash, cash - 2_000_000)
        XCTAssertTrue(g.state.hezQueue.contains(.deed(.radar)))
        XCTAssertEqual(g.accidentChance(b), risk0 * 0.85, accuracy: 1e-12)
        XCTAssertLessThan(g.premium(.L, chance: g.accidentChance(b)).pax, prem0.pax, "premiums drop with the risk")
        XCTAssertEqual(g.state.holding.officeMultiplier(.lux), 1.05, accuracy: 1e-9)
        XCTAssertEqual(g.state.holding.fuelFactor, 1)
        XCTAssertTrue(g.fundResearch())
        XCTAssertEqual(g.state.holding.cash, cash - 6_000_000)
        XCTAssertTrue(g.state.hezQueue.contains(.deed(.composite)))
        XCTAssertEqual(g.state.holding.fuelFactor, 0.75)
        XCTAssertEqual(g.state.holding.upkeepFactor, 0.85)
        XCTAssertEqual(g.state.holding.officeMultiplier(.lux), 1.05 * 1.05, accuracy: 1e-9, "v140: level 4 +5% (was +2%)")
        XCTAssertEqual(g.state.holding.officeMultiplier(.cap), 1.05 * 1.05, accuracy: 1e-9)
        XCTAssertEqual(g.state.envelopeLife, 200)
        XCTAssertTrue(g.state.met(.research))
        XCTAssertFalse(g.fundResearch(), "four levels in all")
        XCTAssertEqual(try reload(g).state.holding.research, 4)
    }

    func testCompositeBasketSavesFuelAndUpkeepInTheDay() {
        func fuelAndUpkeep(_ level: Int) -> (Int, Int) {
            var g = rich()
            g.state.holding.research = level
            for _ in 0..<4 { g.addBalloon(.M) }
            g.state.selfFly = false
            for _ in 0..<5 { g.state.local.pilots.append(contentsOf: g.state.local.candidates.prefix(1)); g.state.local.candidates = Array(g.state.local.candidates.dropFirst()) }
            g.assignPilots()
            g.state.weather?.flag = .green
            g.launch(skip: false)
            let r = g.finishDay(flight: nil)
            return (r.ledger.fuel, r.ledger.upkeep)
        }
        let (f3, u3) = fuelAndUpkeep(3), (f4, u4) = fuelAndUpkeep(4)
        XCTAssertGreaterThan(u3, 0)
        XCTAssertEqual(Double(u4), Double(u3) * 0.85, accuracy: 1)
        XCTAssertGreaterThan(f3, 0)
        XCTAssertEqual(Double(f4), Double(f3) * 0.75, accuracy: Double(f3) * 0.02 + 1)
    }

    // MARK: Records ladder

    func testRecordLadder() throws {
        XCTAssertEqual(RecordAttempt.allCases, [.altitude, .pacific, .world], "price and difficulty rise")
        XCTAssertEqual(RecordAttempt.allCases.map(\.cost), [1_500_000, 4_000_000, 8_000_000], "v140")
        XCTAssertEqual(RecordAttempt.allCases.map(\.days), [25, 40, 60])
        XCTAssertEqual(RecordAttempt.allCases.map(\.odds), [0.65, 0.5, 0.4])
        XCTAssertEqual(RecordAttempt.allCases.map(\.boost), [0.05, 0.1, 0.15])
        var g = rich()
        g.state.parked[.lux] = ParkedRegion(state: g.newRegionState(.lux), auto: Autopilot(base: 1000, since: g.state.day, lastIssue: g.state.day))
        XCTAssertTrue(g.state.recordsOpen)
        XCTAssertTrue(g.state.recordLocked(.world))
        XCTAssertFalse(g.startRecord(.world), "after the Pacific crossing")
        g.state.holding.records = [.pacific: 1, .altitude: 1]
        g.state.holding.recordBoost = 0.25
        XCTAssertEqual(g.state.recordCeiling, 0.25, accuracy: 1e-9)
        let cash = g.state.holding.cash
        XCTAssertTrue(g.startRecord(.world))
        XCTAssertEqual(g.state.holding.cash, cash - 8_000_000)
        XCTAssertEqual(g.state.holding.record, RecordRun(kind: .world, done: g.state.day + 60))
        XCTAssertFalse(g.startRecord(.altitude), "one attempt at a time")
        // Dubai takes a quarter off
        g.state.holding.offices[.dxb] = 1
        XCTAssertEqual(g.state.holding.recordCost(.world), 6_000_000)
        XCTAssertEqual(g.state.holding.recordCost(.pacific), 3_000_000)
        XCTAssertEqual(g.state.holding.recordCost(.altitude), 1_125_000)
        // a set round-the-world record raises the ceiling to 35%
        g.state.holding.records?[.world] = 5
        XCTAssertEqual(g.state.recordCeiling, 0.35, accuracy: 1e-9)
        let back = try reload(g)
        XCTAssertEqual(back.state.holding.record?.kind, .world, "a new save isn't migrated again")
        XCTAssertEqual(back.state.holding.records?[.world], 5)
    }

    func testRoundTheWorldFirstTryIsNotSure() {
        var wins = 0
        for seed in 0..<200 {
            var g = Game(company: "Test Air", colors: Rules.palettes[0], seed: UInt64(seed))
            g.state.holding.records = [.pacific: 1]
            g.state.holding.recordBoost = 0.1
            g.state.holding.record = RecordRun(kind: .world, done: g.state.day)
            _ = g.recordDay()
            if g.state.recordSet(.world) {
                wins += 1
                XCTAssertEqual(g.state.holding.recordBoost ?? 0, 0.25, accuracy: 1e-9)
            }
            XCTAssertNil(g.state.holding.record)
        }
        XCTAssertGreaterThan(wins, 55)
        XCTAssertLessThan(wins, 105)
        // the first two still succeed the first time
        for k in [RecordAttempt.altitude, .pacific] {
            var g = Game(company: "Test Air", colors: Rules.palettes[0], seed: 1)
            g.state.holding.record = RecordRun(kind: k, done: g.state.day)
            _ = g.recordDay()
            XCTAssertTrue(g.state.recordSet(k))
        }
    }

    func testRoundTheWorldRaisesTheBoostCeiling() {
        var g = Game(company: "Test Air", colors: Rules.palettes[0], seed: 3)
        g.state.holding.records = [.pacific: 1, .altitude: 1]
        g.state.holding.recordBoost = 0.25
        var tries = 0
        while !g.state.recordSet(.world) && tries < 50 {
            g.state.holding.record = RecordRun(kind: .world, done: g.state.day)
            _ = g.recordDay()
            tries += 1
        }
        XCTAssertTrue(g.state.recordSet(.world))
        XCTAssertEqual(g.state.holding.recordBoost ?? 0, 0.35, accuracy: 1e-9, "25% + 15%, held at the new ceiling")
    }

    /// Before the new ladder `world` was the €900,000 attempt: it becomes the Pacific crossing (same price, odds and boost).
    func testOldRecordsMoveToTheNewLadder() throws {
        var g = rich()
        g.state.holding.records = [.altitude: 3, .world: 7]
        g.state.holding.record = RecordRun(kind: .world, done: g.state.day + 5)
        g.state.holding.recordBoost = 0.15
        g.state.holding.recordsV2 = nil // an older save has no key
        let back = try reload(g)
        XCTAssertEqual(back.state.holding.records, [.altitude: 3, .pacific: 7])
        XCTAssertEqual(back.state.holding.record?.kind, .pacific)
        XCTAssertEqual(back.state.holding.recordBoost, 0.15)
        XCTAssertEqual(back.state.holding.recordsV2, true)
        XCTAssertFalse(back.state.recordLocked(.world), "the round-the-world flight is open to them")
        XCTAssertEqual(try reload(back).state.holding.records, [.altitude: 3, .pacific: 7], "only once")
    }

    // MARK: Offices

    /// v141: every region entered, so every office can open (Dubai with the Mara, London with Bristol, …).
    func everywhere() -> Game {
        var g = rich()
        g.state.barons[.abq] = 1; XCTAssertTrue(g.enterRegion(.lux))
        g.state.barons[.lux] = 1; XCTAssertTrue(g.enterRegion(.bri))
        g.state.barons[.bri] = 1; XCTAssertTrue(g.enterRegion(.mara))
        g.state.hezQueue = []
        return g
    }

    /// v141: Dubai lifts the Maasai Mara (it was Luxor), London (was Paris) lifts Bristol.
    func testDubaiAndLondon() {
        var g = everywhere()
        XCTAssertEqual(Office.allCases.map(\.cost), [650_000, 750_000, 700_000, 700_000, 700_000, 750_000], "all about €700,000")
        XCTAssertTrue(g.openOffice(.dxb))
        XCTAssertEqual(g.state.hezQueue.last, .officeOpened(.dxb))
        XCTAssertTrue(g.openOffice(.lon))
        XCTAssertEqual(g.state.holding.officeMultiplier(.mara), 1.2, accuracy: 1e-9)
        XCTAssertEqual(g.state.holding.officeMultiplier(.lux), 1, accuracy: 1e-9, "Luxor's +20% is Tokyo's now")
        XCTAssertEqual(g.state.holding.officeMultiplier(.bri), 1.2, accuracy: 1e-9)
        XCTAssertEqual(g.state.holding.officeMultiplier(.cap), 1, accuracy: 1e-9)
        XCTAssertFalse(g.openOffice(.lon), "one each")
    }

    func testExpenseRateFourAnyOfficesThenSix() {
        var g = everywhere()
        XCTAssertEqual(g.state.holding.expenseRate, 0.25)
        for o in [Office.dxb, .lon, .ist] { XCTAssertTrue(g.openOffice(o)) }
        XCTAssertEqual(g.state.holding.expenseRate, 0.25, "three offices")
        XCTAssertTrue(g.openOffice(.sel))
        XCTAssertEqual(g.state.holding.expenseRate, 0.2, "any four (developer)")
        XCTAssertEqual(g.state.hezQueue.last, .allOffices)
        XCTAssertTrue(g.openOffice(.nyc))
        XCTAssertEqual(g.state.holding.expenseRate, 0.2)
        XCTAssertTrue(g.openOffice(.tyo))
        XCTAssertEqual(g.state.holding.expenseRate, 0.15, "all six")
        XCTAssertEqual(g.state.hezQueue.last, .sixOffices)
        // the original four alone still give 20%
        var h = Holding()
        for o in [Office.ist, .nyc, .sel, .tyo] { h.offices[o] = 1 }
        XCTAssertEqual(h.expenseRate, 0.2)
    }

    // MARK: Goals and saves

    func testGoalsWantSixOfficesAndAllResearch() {
        var g = rich()
        g.state.barons[.lux] = 3
        g.state.holding.millionOn = 1
        g.flewMaraGroup()
        g.state.holding.celebrity = Celebrity(index: 0, until: 100)
        g.state.holding.worldGamesUntil = 60
        g.state.holding.research = 2
        for o in [Office.ist, .nyc, .sel, .tyo] { g.state.holding.offices[o] = 1 }
        g.checkHoldingGoals()
        XCTAssertNil(g.state.holding.worldBaron)
        XCTAssertFalse(g.state.done(.offices))
        XCTAssertFalse(g.state.done(.research))
        g.state.holding.offices[.dxb] = 2
        g.state.holding.offices[.lon] = 2
        g.state.holding.research = 4
        g.checkHoldingGoals()
        XCTAssertNotNil(g.state.holding.worldBaron)
        XCTAssertEqual(HoldingGoal.allCases, HoldingGoal.order1412,
                       "in the order the simulator meets them")
    }

    /// An old save, World Baron with the old goals (four offices, envelope R&D): the title waits for the new ones.
    func testOldWorldBaronIsCheckedAgainOnLoad() throws {
        var g = rich()
        g.state.barons[.lux] = 3
        g.flewMaraGroup()
        g.state.holding.celebrity = Celebrity(index: 0, until: 100)
        g.state.holding.worldGamesUntil = 60
        g.state.holding.research = 2
        g.state.holding.offices = [.ist: 1, .nyc: 1, .sel: 1, .tyo: 1]
        g.state.holding.worldBaron = 300
        g.state.holding.millionOn = nil
        g.state.holding.cash = 5000
        g.state.postcards = [.world: 300]
        var back = try reload(g)
        XCTAssertNil(back.state.holding.worldBaron, "four offices and two R&D levels are no longer enough")
        XCTAssertFalse(back.state.done(.offices))
        XCTAssertFalse(back.state.done(.research))
        XCTAssertTrue(back.state.done(.million), "the million they had reached stays met")
        XCTAssertEqual(back.state.postcards?[.world], 300, "the postcard stays in the album")
        // meeting the new goals makes them World Baron again, without a second postcard
        back.state.holding.offices[.dxb] = 400
        back.state.holding.offices[.lon] = 400
        back.state.holding.research = 4
        back.holdingGoalsNow()
        XCTAssertNotNil(back.state.holding.worldBaron)
        back.checkAchievements()
        XCTAssertFalse((back.state.newPostcards ?? []).contains(.world))
    }

    func testFullWorldBaronStaysOnLoad() throws {
        var g = rich()
        g.state.barons[.lux] = 3
        g.flewMaraGroup()
        g.state.holding.celebrity = Celebrity(index: 0, until: 100)
        g.state.holding.worldGamesUntil = 60
        g.state.holding.research = 4
        for o in Office.allCases { g.state.holding.offices[o] = 1 }
        g.state.holding.worldBaron = 300
        g.state.holding.millionOn = 100
        XCTAssertEqual(try reload(g).state.holding.worldBaron, 300)
    }

    /// A v136 holding, without any v137 key, decodes; the new keys come back after a save.
    func testOldHoldingDecodes() throws {
        let json = #"{"cash":5,"history":[],"todayGross":0,"todayCost":0,"tvUntil":0,"tvCooldown":0,"billboards":{},"research":2,"offices":{"ist":3,"tyo":4},"records":{"world":9}}"#
        var h = try JSONDecoder().decode(Holding.self, from: Data(json.utf8))
        XCTAssertNil(h.documentary)
        XCTAssertEqual(h.offices.count, 2)
        XCTAssertEqual(h.research, 2)
        h.offices[.lon] = 7
        h.documentary = Holding.Documentary(until: 10, next: 20, season: 1)
        h.records?[.pacific] = 8
        XCTAssertNil(h.recordsV2, "an older holding decodes without the new ladder's mark")
        let back = try JSONDecoder().decode(Holding.self, from: JSONEncoder().encode(h))
        XCTAssertEqual(back, h)
    }

    func testOfficesListedInTheDevelopersOrder() {
        XCTAssertEqual(Office.listed, [.ist, .sel, .nyc, .lon, .tyo, .dxb], "v141.1: replaces v138's cheapest first")
        XCTAssertEqual(Office.allCases, [.ist, .nyc, .sel, .tyo, .dxb, .lon], "saved and goal order unchanged")
    }
}
