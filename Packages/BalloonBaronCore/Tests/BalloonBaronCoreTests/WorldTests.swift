import XCTest
@testable import BalloonBaronCore

/// Chapters, regions, the holding, rival mergers and the design studio.
final class WorldTests: XCTestCase {
    func newGame(seed: UInt64 = 42) -> Game {
        var g = Game(company: "Test Air", colors: Rules.palettes[0], seed: seed)
        g.startDay()
        return g
    }

    @discardableResult
    func play(_ g: inout Game) -> DayReport {
        g.startDay()
        while g.nextHezarfen() != nil {}
        if g.launch(skip: g.state.weather?.flag == .red) != nil {
            return g.finishDay(flight: FlightResult(landing: .good, distance: 80))
        }
        return g.finishDay(flight: nil)
    }

    /// A game that has just become Cappadocia's baron.
    func baronGame() -> Game {
        var g = newGame()
        g.state.chapter = 4
        g.state.barons[.cap] = 1
        g.state.local.netHistory = [2000, 2200, 2400]
        return g
    }

    func testPilotsSkipGroundedBalloonsAndSeniorsTakeTheBiggest() {
        var g = newGame()
        g.state.cash = 500000
        g.buyBalloon(.L)
        g.buyBalloon(.M)
        let l = g.state.balloons.first { $0.size == .L }!.id
        let li = g.state.balloons.firstIndex { $0.id == l }!
        g.state.balloons[li].damagedUntil = g.state.day + 3
        g.state.pilots = [Pilot(id: 900, name: "Rookie", level: .rookie), Pilot(id: 901, name: "Senior", level: .senior)]
        g.assignPilots()
        let m = g.state.balloons.first { $0.size == .M }!
        XCTAssertEqual(m.pilot, 901, "the senior flies the biggest balloon that can go up")
        XCTAssertEqual(g.state.balloon(l)?.pilot, 900, "the balloon in repair is served last")
        g.state.pilots.remove(at: 0)
        g.assignPilots()
        XCTAssertEqual(g.state.balloon(l)?.pilot, nil, "no pilot is wasted on a balloon in repair")
        g.state.pilots.append(Pilot(id: 902, name: "Spare", level: .rookie))
        g.state.balloons[li].damagedUntil = 0
        g.state.balloons[li].flights = 999
        g.assignPilots()
        XCTAssertEqual(g.state.balloon(l)?.pilot, 902)
        g.state.pilots.append(Pilot(id: 903, name: "Idle", level: .rookie))
        g.assignPilots()
        XCTAssertEqual(g.state.idlePilots.map(\.id), [903])
        XCTAssertEqual(g.state.sortedFleet.first?.id, g.state.flagship)
        XCTAssertEqual(g.state.sortedFleet.dropFirst().map(\.size), [.L, .M])
    }

    func testTouristsDontDependOnPrice() {
        var g = newGame()
        let a = g.touristsToday()
        g.setPrice(300)
        XCTAssertEqual(g.touristsToday(), a)
        XCTAssertLessThan(g.estimatedIncome().pax, g.estimatedIncome(price: 150).pax)
        XCTAssertEqual(Game.feel(price: 40), 0)
        XCTAssertLessThan(Game.feel(price: 200), Game.feel(price: 260))
    }

    func testAntitrustFineFollowsCompanyWorth() {
        var g = newGame()
        g.state.day = 40
        g.state.cash = -1000
        g.state.balloons = (0..<20).map { Balloon(id: 100 + $0, size: .L, name: "B\($0)") }
        g.state.flagship = 100
        // Pilots for the whole fleet, so the share really is over 60% on a day the fine can come.
        g.state.pilots = (0..<20).map { Pilot(id: 900 + $0, name: "P\($0)", level: .rookie) }
        g.state.monopolyDays = 50
        g.state.festivalNext = 999 // no festival crowds: the cash box stays empty
        var fine = 0, cashAtFine = 0
        for _ in 0..<80 where fine == 0 {
            g.state.monopolyDays = 50
            g.state.cash = -1000
            let r = play(&g)
            fine = r.ledger.antitrust
            // The day's takings were in the box when the fine came; a seizure after it doesn't count.
            cashAtFine = -1000 + r.net + fine - r.ledger.seizure
        }
        XCTAssertGreaterThan(fine, 0)
        XCTAssertEqual(fine, jsRound(Double(max(0, cashAtFine) + 20 * 60000) * Rules.monopolyRate / 100) * 100,
                       "3% of company worth: the balloons count even when the cash box is empty")
    }

    func testFoundingChapterPaysTheAward() {
        var g = newGame()
        g.state.cash = 200000
        g.buyBalloon(.S)
        XCTAssertTrue(g.hire(g.state.candidates[0].id))
        g.state.rep = 1.15
        g.signHotel(.stone)
        g.upgrade(.mast)
        let r = play(&g)
        XCTAssertEqual(g.state.chapter, 1)
        XCTAssertEqual(r.ledger.chapterReward, 5000)
        XCTAssertTrue(r.events.contains(.chapterDone("founding", reward: 5000)))
        XCTAssertEqual(g.state.chapterNews, ChapterNews(region: .cap, index: 0))
        XCTAssertEqual(g.state.currentChapter?.id, "rising")
    }

    func testBaronOpensTheHolding() {
        var g = newGame()
        g.state.chapter = 3
        g.state.cash = 900000
        g.state.rep = 1.4
        g.state.school = true
        g.state.ownHotels = [.stone, .mansion]
        g.state.shareNow = 0.8
        g.buyBalloon(.XL)
        g.state.buildings = [.mast: 3]
        // Fly with almost the whole market so the share stays above 70%.
        for i in g.state.rivals.indices { g.state.rivals[i].alive = false; g.state.rivals[i].deadDay = 1 }
        let r = play(&g)
        XCTAssertTrue(g.state.isBaron(.cap))
        XCTAssertTrue(r.events.contains(.baron(.cap)))
        XCTAssertTrue(g.state.hezQueue.contains(.holdingOpened) || g.state.tipsSeen.isEmpty == false)
    }

    func testWithdrawConvertsAndNeverGoesBack() {
        var g = newGame()
        g.state.cash = 50000
        XCTAssertEqual(g.withdraw(share: 0.5), 25000)
        XCTAssertEqual(g.state.holding.cash, 25000)
        XCTAssertEqual(g.withdraw(share: 1), 15000, "all but €10,000")
        XCTAssertEqual(g.state.cash, Holding.withdrawKeep)
        XCTAssertEqual(g.withdraw(share: 0.25), 0)
        XCTAssertEqual(g.state.holding.history.last?.income, 40000)
    }

    func testEnteringAlbuquerqueParksCappadocia() {
        var g = baronGame()
        g.state.holding.cash = 150000
        g.state.cash = 42000
        XCTAssertTrue(g.enterRegion(.abq))
        XCTAssertEqual(g.state.region, .abq)
        XCTAssertEqual(g.state.holding.cash, 50000)
        XCTAssertEqual(g.state.cash, Rules.startCash, "a fresh start in dollars")
        XCTAssertEqual(g.state.balloons.map(\.name), ["Sandia"])
        XCTAssertEqual(g.state.rivals.map(\.name), ["Sandia Sky Rides", "Rio Grande Balloons", "Route 66 Air"])
        XCTAssertEqual(g.state.parked[.cap]?.state.cash, 42000, "Cappadocia keeps its own cash box")
        XCTAssertEqual(g.state.parked[.cap]?.auto.base ?? 0, 2200 * 0.85, accuracy: 0.01)
        XCTAssertNotNil(g.state.fiestaNext)
        XCTAssertNotNil(g.state.weather)
        // Box winds: low layer one way, the next one back.
        let l = g.state.weather!.layers
        XCTAssertLessThan(l[0], 0)
        XCTAssertGreaterThan(l[1], 0)

        let before = g.state.holding.cash
        let r = play(&g)
        XCTAssertGreaterThan(r.ledger.holdingNet, 0)
        XCTAssertEqual(g.state.holding.cash - before, r.ledger.holdingNet)
        XCTAssertEqual(g.state.holding.todayCost, jsRound(Double(g.state.holding.todayGross) * 0.25))

        // Going back swaps the boxes.
        g.switchRegion(.cap)
        XCTAssertEqual(g.state.cash, 42000)
        XCTAssertNotNil(g.state.parked[.abq])
        XCTAssertEqual(g.state.region, .cap)
    }

    func testFiestaComesEveryThirtyDays() {
        var g = baronGame()
        g.state.holding.cash = 100000
        g.enterRegion(.abq)
        g.state.winter = nil
        g.state.nextWinter = 999
        var start: Int?
        for _ in 0..<20 {
            play(&g)
            if g.state.fiesta != nil && start == nil { start = g.state.day }
        }
        XCTAssertNotNil(start)
        let f = g.state.fiesta ?? Fiesta(start: 0, end: 0)
        if g.state.fiesta != nil { XCTAssertEqual(f.end - f.start, 3) }
        for _ in 0..<5 { play(&g) }
        XCTAssertNil(g.state.fiesta)
        XCTAssertGreaterThan(g.state.fiestaFlown, 0)
        XCTAssertGreaterThan(g.state.fiestaNext ?? 0, g.state.day + 20)
    }

    func testIssuesHalveIncomeUntilAnswered() {
        var g = baronGame()
        g.state.holding.cash = 1_000_000
        g.enterRegion(.abq)
        var p = g.state.parked[.cap]!
        p.auto.issue = .init(kind: .envelope, day: g.state.day)
        g.state.parked[.cap] = p
        let cost = Issue.envelope.cost(.a, base: p.auto.base)
        XCTAssertGreaterThan(cost, 0)
        let before = g.state.holding.cash
        XCTAssertTrue(g.resolveIssue(in: .cap, choice: .a))
        XCTAssertEqual(g.state.holding.cash, before - cost)
        XCTAssertNil(g.state.parked[.cap]?.auto.issue)

        p = g.state.parked[.cap]!
        p.auto.issue = .init(kind: .accident, day: g.state.day)
        g.state.parked[.cap] = p
        XCTAssertTrue(g.resolveIssue(in: .cap, choice: .a))
        XCTAssertEqual(g.state.region, .cap, "dealing with an accident takes you there")
    }

    func testHoldingInvestmentsAndOffices() {
        var g = baronGame()
        g.state.holding.cash = 3_000_000
        XCTAssertTrue(g.openOffice(.nyc))
        XCTAssertEqual(g.state.holding.tvCost, 187500)
        XCTAssertTrue(g.runTVCampaign())
        XCTAssertFalse(g.runTVCampaign(), "cooldown")
        XCTAssertEqual(g.holdingBoost(.cap), 1.2, accuracy: 1e-9)
        XCTAssertTrue(g.runBillboards())
        XCTAssertEqual(g.holdingBoost(.cap), 1.32, accuracy: 1e-9)
        XCTAssertEqual(g.holdingBoost(.abq), 1.2, accuracy: 1e-9)
        XCTAssertTrue(g.openOffice(.sel))
        XCTAssertEqual(g.state.holding.celebrityCost, 420000)
        XCTAssertTrue(g.signCelebrity())
        XCTAssertEqual(g.state.holding.celebrity?.until, g.state.day + 180)
        XCTAssertTrue(g.fundResearch())
        XCTAssertEqual(g.state.envelopeLife, 160)
        XCTAssertEqual(g.state.holding.expenseRate, 0.25)
        XCTAssertTrue(g.openOffice(.ist))
        XCTAssertTrue(g.openOffice(.tyo))
        XCTAssertEqual(g.state.holding.expenseRate, 0.2)
        XCTAssertEqual(g.state.hezQueue.last, .allOffices)
        XCTAssertEqual(g.state.holding.officeMultiplier(.cap), 1.25)
        XCTAssertEqual(g.state.holding.officeMultiplier(.abq), 1.2)
        XCTAssertEqual(g.designCost, 0)
    }

    func testRivalsMergeAgainstADominantPlayer() {
        var g = newGame()
        g.state.day = 60
        g.state.dominanceDays = 10
        var rev: [DayEvent] = []
        g.mergeRivals(share: 0.62, events: &rev)
        let alive = g.state.rivals.filter(\.alive)
        XCTAssertEqual(alive.count, 2)
        let merged = alive.first { $0.name.contains("&") }!
        XCTAssertEqual(merged.name, "Kızıl & Peribaca Balloons")
        XCTAssertEqual(merged.balloons.count, 7)
        XCTAssertEqual(merged.cash, (12000 + 20000) * 1.3 + 40000)
        XCTAssertEqual(g.state.mergeNews?.sharePercent, 62)
        XCTAssertEqual(g.state.rivals.first { $0.mergedInto != nil }?.mergedInto, merged.name)
        XCTAssertEqual(g.state.lastMerge, 60)
        if case .rivalsMerged = rev.first {} else { XCTFail("merge event") }
    }

    func testRichEntrantOutnumbersYou() {
        var g = newGame()
        g.state.balloons = (0..<12).map { Balloon(id: 100 + $0, size: .M, name: "B\($0)") }
        let f = g.entrantFleet(.bosphorus)
        XCTAssertEqual(f.balloons.count, 15)
        XCTAssertEqual(f.cash, 60000 + 9000 * 15)
        g.state.day = 60
        XCTAssertEqual(g.entrantFleet(.anatolian).balloons.count, 6)
        g.state.day = 10
        XCTAssertEqual(g.entrantFleet(.anatolian).balloons.count, 5)
    }

    func testDesignsScoreAndBringPopularity() {
        var g = newGame()
        g.state.cash = 200000
        XCTAssertNil(g.createDesign(name: "x", pattern: .stars, colors: ["#ff5e3a", "#ffffff", "#1f1b2e"]), "needs a workshop")
        XCTAssertTrue(g.buildWorkshop())
        let id = g.createDesign(name: " Sunset ", pattern: .sunburst, colors: ["#2b2350", "#ffc23d", "#ff5e3a"])!
        let d = g.state.designs[0]
        XCTAssertEqual(d.name, "Sunset")
        XCTAssertEqual(d.score, g.designScore(pattern: .sunburst, colors: d.colors, excluding: d.id))
        XCTAssertLessThan(g.designScore(pattern: .sunburst, colors: d.colors), d.score, "repeating yourself costs points")
        XCTAssertLessThan(g.designScore(pattern: .dots, colors: ["#5aa9e6", "#ffffff", "#ffffff"]),
                          g.designScore(pattern: .dots, colors: ["#ffc23d", "#2b2350", "#ff5e3a"]), "a rival's color costs points")
        XCTAssertTrue(g.paint(g.state.flagship, design: id))
        XCTAssertEqual(g.state.cash, 200000 - Studio.workshopCost - Studio.designCost - Studio.reskinCost)
        let r = play(&g)
        XCTAssertEqual(r.ledger.designRep, 0.003 * Double(d.score) / 100, accuracy: 1e-9)
        g.state.day += 100
        XCTAssertEqual(g.freshness(d), 0.2)
    }

    func testSaveRoundTripWithWorld() throws {
        var g = baronGame()
        g.state.holding.cash = 400000
        g.openOffice(.ist)
        g.enterRegion(.abq)
        play(&g)
        let data = try JSONEncoder().encode(g.state)
        let back = try JSONDecoder().decode(GameState.self, from: data)
        XCTAssertEqual(back, g.state)
    }

    /// A save from the three-chapter plan keeps its place: past the founding chapter it skips the new second one.
    func testThreeChapterSavesShiftAhead() throws {
        var g = baronGame()
        g.state.holding.cash = 150000
        XCTAssertTrue(g.enterRegion(.abq))
        g.state.local.chapter = 2
        g.state.parked[.cap]?.state.chapter = 3
        g.state.chapterNews = ChapterNews(region: .abq, index: 1)
        g.state.version = 3
        let old = try JSONDecoder().decode(GameState.self, from: JSONEncoder().encode(g.state))
        let s = Game(state: old).state
        XCTAssertEqual(s.version, 4)
        XCTAssertEqual(s.local.chapter, 3)
        XCTAssertEqual(s.currentChapter?.id, "baronAbq")
        XCTAssertEqual(s.parked[.cap]?.state.chapter, 4)
        XCTAssertEqual(s.chapterNews, ChapterNews(region: .abq, index: 2))
        XCTAssertEqual(Game(state: s).state, s, "a current save is left alone")
    }

    /// A goal-driven player becomes Cappadocia's baron within a reasonable time.
    func testChaptersAreReachable() {
        var reached = 0
        for seed: UInt64 in [1, 2, 3] {
            var g = newGame(seed: seed)
            for _ in 0..<220 where !g.state.isBaron(.cap) && !g.state.over {
                play(&g)
                g.state.chapterNews = nil
                g.state.mergeNews = nil
                let s = g.state
                if s.winter == nil {
                    if s.balloons.count < (s.chapter >= 3 && s.shareNow < 0.7 ? 22 : 14) && s.cash > 70000 { g.buyBalloon(.M) } else if s.balloons.count < 5 && s.cash > 22000 { g.buyBalloon(.S) }
                }
                while g.state.balloons.contains(where: { g.state.status($0) == .noPilot }), let c = g.state.candidates.first { g.hire(c.id) }
                if s.balloons.count >= 4 { for h in Hotel.allCases where !g.state.hotelActive(h) { g.signHotel(h) } }
                if s.chapter >= 1 {
                    g.runGuideFlight(); g.runInfluencer()
                    if s.cash > 150000 { g.buildWorkshop() }
                    for h in Hotel.allCases where g.state.cash > h.buyPrice + 30000 { g.buyHotel(h) }
                }
                if s.chapter >= 3 {
                    if !s.school && s.cash > 90000 { g.buildSchool() }
                    if s.cash > 200000 { g.buyBalloon(.XL) }
                }
                // The chapters ask for buildings: the mast, then the hangar, then one at the top level.
                let want: Building? = g.state.level(.mast) < 2 ? .mast : s.chapter >= 1 && g.state.level(.hangar) < 2 ? .hangar
                    : s.chapter >= 3 && g.state.topBuildingLevel < 3 ? .hangar : nil
                if let b = want, let c = b.upgradeCost(from: g.state.level(b)), g.state.cash > c + 20000 { g.upgrade(b) }
                if let o = g.state.poach { g.answerPoach(match: o.wage <= 400) }
                for b in g.state.balloons where g.state.condition(b) <= 0 { g.renewEnvelope(b.id) }
                g.setPrice(g.state.rep > 1.2 ? 200 : 175)
            }
            print("seed \(seed): chapter \(g.state.chapter) day \(g.state.day) baron \(g.state.isBaron(.cap)) share \(g.state.shareNow)")
            if g.state.isBaron(.cap) { reached += 1 }
            XCTAssertGreaterThanOrEqual(g.state.chapter, 1, "seed \(seed): the founding chapter is easy")
        }
        print("barons: \(reached)/3")
        XCTAssertGreaterThanOrEqual(reached, 2, "a focused player should become baron by day 220")
    }
}
