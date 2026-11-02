import XCTest
@testable import BalloonBaronCore

/// v136 (TestFlight): the holding's worldwide deals (celebrity, jersey, World Games, a world record) lift popularity in
/// every region you own, whichever region you buy them from. TV and billboards are bought for each region on its own,
/// from any region.
final class Campaigns136Tests: XCTestCase {
    /// Cappadocia, Albuquerque and Luxor owned, playing in `here` with the other two parked.
    func threeRegions(in here: RegionID = .lux) -> Game {
        var g = Game(company: "Test Air", colors: Rules.palettes[0], seed: 42)
        g.state.tutorial = TutorialState(done: true)
        g.startDay()
        g.state.chapter = 4
        g.state.barons[.cap] = 1
        g.grantStoreItem(.worldTour)
        g.state.local.netHistory = [20000, 22000, 24000]
        g.state.holding.cash = 1_000_000
        g.state.cash = 50_000
        XCTAssertTrue(g.enterRegion(.abq))
        g.state.barons[.abq] = 2
        XCTAssertTrue(g.enterRegion(.lux))
        if here != .lux { g.switchRegion(here) }
        XCTAssertEqual(g.state.region, here)
        XCTAssertEqual(g.state.parked.count, 2)
        g.state.holding.cash = 50_000_000
        g.state.barons[.bri] = 5 // opens the World Games show
        return g
    }

    func rep(_ g: Game, _ r: RegionID) -> Double { r == g.state.region ? g.state.rep : g.state.parked[r]!.state.rep }

    func set(_ g: inout Game, _ r: RegionID, _ v: Double) {
        if r == g.state.region { g.state.rep = v } else { g.state.parked[r]!.state.rep = v }
    }

    let regions: [RegionID] = [.cap, .abq, .lux]

    func check(_ name: String, _ d: Double, _ buy: (inout Game) -> Bool) {
        for here in regions {
            var g = threeRegions(in: here)
            set(&g, .cap, 1.0); set(&g, .abq, 1.38); set(&g, .lux, 0.6)
            XCTAssertTrue(buy(&g), "\(name) from \(here)")
            XCTAssertEqual(rep(g, .cap), 1.0 + d, accuracy: 1e-9, "\(name) from \(here): Cappadocia")
            XCTAssertEqual(rep(g, .abq), 1.4, accuracy: 1e-9, "\(name) from \(here): Albuquerque stops at its cap")
            XCTAssertEqual(rep(g, .lux), 0.6 + d, accuracy: 1e-9, "\(name) from \(here): Luxor")
        }
    }

    func testCelebrityLiftsEveryRegion() { check("celebrity", Holding.celebrityRep) { $0.signCelebrity() } }
    func testJerseyLiftsEveryRegion() { check("jersey", Holding.jerseyRep) { $0.sponsorJersey() } }
    func testWorldGamesLiftsEveryRegion() { check("World Games", Holding.worldGamesRep) { $0.holdWorldGamesShow() } }

    func testCardNumbersMatchTheRule() {
        // the cards show the star value (×4): TV +0.4★, celebrity +0.6★, jersey +0.4★, World Games +0.8★
        XCTAssertEqual(Holding.tvRep * 4, 0.4, accuracy: 1e-9)
        XCTAssertEqual(Holding.celebrityRep * 4, 0.6, accuracy: 1e-9)
        XCTAssertEqual(Holding.jerseyRep * 4, 0.4, accuracy: 1e-9)
        XCTAssertEqual(Holding.worldGamesRep * 4, 0.8, accuracy: 1e-9)
    }

    func testTheOutcomeDoesNotDependOnWhereYouBuy() {
        var reps: [[Double]] = []
        for here in regions {
            var g = threeRegions(in: here)
            set(&g, .cap, 0.9); set(&g, .abq, 1.1); set(&g, .lux, 0.7)
            XCTAssertTrue(g.sponsorJersey())
            XCTAssertTrue(g.signCelebrity())
            reps.append(regions.map { rep(g, $0) })
        }
        XCTAssertEqual(reps[0], reps[1])
        XCTAssertEqual(reps[1], reps[2])
    }

    func testARegionEnteredLaterKeepsItsOwnStart() {
        var g = Game(company: "Test Air", colors: Rules.palettes[0], seed: 7)
        g.state.tutorial = TutorialState(done: true)
        g.startDay()
        g.state.chapter = 4
        g.state.barons[.cap] = 1
        g.grantStoreItem(.worldTour)
        g.state.holding.cash = 2_000_000
        g.state.cash = 50_000
        XCTAssertTrue(g.signCelebrity())
        XCTAssertTrue(g.enterRegion(.abq))
        XCTAssertEqual(g.state.rep, RegionState(rivals: []).rep, accuracy: 1e-9, "the campaign's bump happened before Albuquerque was entered")
    }

    func testAWorldRecordLiftsEveryRegionAndIsInTheReport() {
        var g = threeRegions(in: .abq)
        set(&g, .cap, 1.0); set(&g, .abq, 1.0); set(&g, .lux, 1.0)
        g.state.holding.record = RecordRun(kind: .altitude, done: g.state.day)
        g.launch(skip: true)
        let report = g.finishDay(flight: nil)
        XCTAssertNotNil(g.state.holding.records?[.altitude])
        XCTAssertEqual(report.repWhy?[.record] ?? 0, RecordAttempt.rep, accuracy: 1e-9)
        XCTAssertEqual(rep(g, .cap), 1.0 + RecordAttempt.rep, accuracy: 0.02, "parked Cappadocia")
        XCTAssertEqual(rep(g, .lux), 1.0 + RecordAttempt.rep, accuracy: 0.02, "parked Luxor")
    }

    func testBillboardsStayInTheirRegion() {
        var g = threeRegions(in: .lux)
        let d = g.state.day
        XCTAssertTrue(g.runBillboards())
        XCTAssertEqual(g.state.holding.billboards, [.lux: d + Holding.billboardDays])
        XCTAssertFalse(g.runBillboards(), "one set per region at a time")
        XCTAssertEqual(g.holdingBoost(.lux), 1.1, accuracy: 1e-9)
        XCTAssertEqual(g.holdingBoost(.cap), 1, accuracy: 1e-9)
        let r = [rep(g, .cap), rep(g, .abq), rep(g, .lux)]
        g.switchRegion(.cap)
        XCTAssertEqual(g.state.holding.billboards[.cap], nil, "Cappadocia has none: its card offers to put some up")
        XCTAssertTrue(g.runBillboards())
        XCTAssertEqual(g.state.holding.billboards[.lux], d + Holding.billboardDays, "Luxor's stay where they are")
        XCTAssertEqual(g.state.holding.billboards[.cap], d + Holding.billboardDays)
        XCTAssertEqual([rep(g, .cap), rep(g, .abq), rep(g, .lux)], r, "billboards add demand, not popularity")
    }

    // MARK: TV per region

    func testTVForAParkedRegionFromAnotherRegion() {
        var g = threeRegions(in: .cap)
        set(&g, .cap, 1.0); set(&g, .abq, 1.0); set(&g, .lux, 1.0)
        let d = g.state.day, cash = g.state.holding.cash
        XCTAssertTrue(g.runTVCampaign(in: .lux))
        XCTAssertEqual(g.state.holding.cash, cash - Holding.tvCost)
        XCTAssertEqual(g.state.holding.tv?[.lux], Holding.TVRun(until: d + Holding.tvDays, cooldown: d + Holding.tvCooldown))
        XCTAssertEqual(rep(g, .lux), 1.0 + Holding.tvRep, accuracy: 1e-9, "Luxor's popularity")
        XCTAssertEqual(rep(g, .cap), 1.0, accuracy: 1e-9, "not the region you're standing in")
        XCTAssertEqual(rep(g, .abq), 1.0, accuracy: 1e-9)
        XCTAssertEqual(g.holdingBoost(.lux), 1.2, accuracy: 1e-9)
        XCTAssertEqual(g.holdingBoost(.cap), 1, accuracy: 1e-9)
        XCTAssertEqual(g.holdingBoost(.abq), 1, accuracy: 1e-9)
        XCTAssertEqual(g.state.holding.tvCount, 1, "the TV goal counts any region's campaign")
    }

    func testTVCooldownsArePerRegion() {
        var g = threeRegions(in: .abq)
        let d = g.state.day
        XCTAssertTrue(g.runTVCampaign(in: .cap))
        XCTAssertFalse(g.canRunTV(in: .cap))
        XCTAssertFalse(g.runTVCampaign(in: .cap), "Cappadocia waits 30 days")
        XCTAssertTrue(g.canRunTV(in: .abq))
        XCTAssertTrue(g.runTVCampaign(), "the region you're in still can")
        XCTAssertTrue(g.runTVCampaign(in: .lux))
        XCTAssertEqual(g.state.holding.tvCount, 3)
        XCTAssertFalse(g.runTVCampaign(in: .bri), "not a region you own")
        g.state.day = d + Holding.tvDays
        XCTAssertEqual(g.holdingBoost(.cap), 1, accuracy: 1e-9, "the run is over")
        XCTAssertFalse(g.canRunTV(in: .cap))
        g.state.day = d + Holding.tvCooldown
        XCTAssertTrue(g.canRunTV(in: .cap))
        XCTAssertTrue(g.runTVCampaign(in: .cap))
    }

    func testFourRegionsCostAboutTheOldNationalCampaign() {
        XCTAssertEqual(Holding.tvCost * 4, 240_000, "the old one cost 250,000 for every region")
    }

    func testAnOldSavesNationalTVStillCoversEveryRegion() throws {
        var g = threeRegions(in: .cap)
        let d = g.state.day
        // a save from before v136: one national run with its wait, no per-region record
        g.state.holding.tvUntil = d + 5
        g.state.holding.tvCooldown = d + 21
        let json = String(decoding: try JSONEncoder().encode(g.state), as: UTF8.self)
        XCTAssertFalse(json.contains("\"tv\":"))
        var back = Game(state: try JSONDecoder().decode(GameState.self, from: Data(json.utf8)))
        XCTAssertNil(back.state.holding.tv)
        for r in regions {
            XCTAssertEqual(back.holdingBoost(r), 1.2, accuracy: 1e-9, "the old run still lifts \(r)")
            XCTAssertFalse(back.canRunTV(in: r), "and its wait still holds in \(r)")
        }
        back.state.day = d + 21
        XCTAssertTrue(back.canRunTV(in: .abq))
        XCTAssertTrue(back.runTVCampaign(in: .abq))
        XCTAssertEqual(back.holdingBoost(.abq), 1.2, accuracy: 1e-9)
        XCTAssertEqual(back.holdingBoost(.cap), 1, accuracy: 1e-9)
        XCTAssertEqual(back.state.holding.tvUntil, d + 5, "a new campaign never writes the old national fields")
    }

    func testBillboardsForAParkedRegionFromAnotherRegion() {
        var g = threeRegions(in: .cap)
        let d = g.state.day
        XCTAssertTrue(g.runBillboards(in: .abq))
        XCTAssertEqual(g.state.holding.billboards, [.abq: d + Holding.billboardDays])
        XCTAssertFalse(g.runBillboards(in: .abq))
        XCTAssertFalse(g.runBillboards(in: .bri), "not a region you own")
        XCTAssertEqual(g.holdingBoost(.abq), 1.1, accuracy: 1e-9)
        XCTAssertEqual(g.holdingBoost(.cap), 1, accuracy: 1e-9)
        XCTAssertEqual(g.ownedRegions, [.cap, .abq, .lux])
    }
}
