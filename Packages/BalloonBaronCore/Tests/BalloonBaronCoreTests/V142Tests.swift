import XCTest
@testable import BalloonBaronCore

/// v142 (version 1.0.1, developer): the report names the brought balloons' instalment, the Hot Air Foundation is priced
/// per region (`Holding140Tests` checks the prices), and each region has its own workshop lines.
final class V142Tests: XCTestCase {
    /// Cappadocia with a workshop at `level`, its baron, the Grand Tour owned and a rich holding.
    func baron(level: Int = 4, seed: UInt64 = 42) -> Game {
        var g = Game(company: "Test Air", colors: Rules.palettes[0], seed: seed)
        g.state.tutorial = TutorialState(done: true)
        g.startDay()
        g.state.chapter = 4
        g.state.barons[.cap] = 1
        g.grantStoreItem(.worldTour)
        g.state.local.netHistory = [20000, 22000, 24000]
        g.state.cash = 1_000_000
        XCTAssertTrue(g.buildWorkshop())
        while g.state.factoryLevel < level { XCTAssertTrue(g.upgradeFactory()) }
        g.state.holding.cash = 10_000_000
        return g
    }

    func play(_ g: inout Game) {
        g.startDay()
        while g.nextHezarfen() != nil {}
        if g.state.transferAsk != nil { g.skipTransfer() }
        if g.launch() != nil { _ = g.finishDay(flight: FlightResult(landing: .good, distance: 120)) } else { _ = g.finishDay(flight: nil) }
    }

    func reload(_ g: Game) throws -> Game {
        Game(state: try JSONDecoder().decode(GameState.self, from: JSONEncoder().encode(g.state)))
    }

    // MARK: The brought balloons' instalment

    func testReportNamesTheInstalment() {
        var g = baron()
        g.state.local.transferDebt = TransferDebt(left: Transfer.debtDays, installment: 500, from: .abq)
        g.startDay()
        _ = g.launch(skip: true)
        var r = g.finishDay(flight: nil)
        XCTAssertEqual(r.ledger.transfer, 500)
        XCTAssertEqual(r.ledger.transferNo, 1, "the first of 30")
        g.state.local.transferDebt?.left = 24
        g.startDay()
        _ = g.launch(skip: true)
        r = g.finishDay(flight: nil)
        XCTAssertEqual(r.ledger.transferNo, 7, "instalment 7/30")
        g.state.local.transferDebt?.left = 1
        g.startDay()
        _ = g.launch(skip: true)
        r = g.finishDay(flight: nil)
        XCTAssertEqual(r.ledger.transferNo, Transfer.debtDays, "the last")
        XCTAssertNil(g.state.local.transferDebt)
    }

    /// A report saved before v142 has no instalment number and still loads.
    func testOldLedgerDecodes() throws {
        var lg = Ledger()
        lg.transfer = 300
        let json = try XCTUnwrap(String(data: JSONEncoder().encode(lg), encoding: .utf8))
        XCTAssertFalse(json.contains("transferNo"))
        let back = try JSONDecoder().decode(Ledger.self, from: Data(json.utf8))
        XCTAssertNil(back.transferNo)
        XCTAssertEqual(back.transfer, 300)
    }

    // MARK: The workshop's lines per region

    func testNewRegionStartsAtLevelOneAndKeepsItsOwnLines() throws {
        var g = baron()
        XCTAssertEqual(g.state.factoryLevel, 4)
        XCTAssertTrue(g.enterRegion(.abq))
        XCTAssertEqual(g.state.factoryLevel, 1, "the workshop is open in Albuquerque, the lines are not")
        XCTAssertNotNil(g.state.workshopDay, "the workshop itself is company-wide")
        XCTAssertTrue(g.state.factorySizes.isEmpty)
        XCTAssertEqual(g.state.factoryNextCost, 30000, "the same number in dollars")
        XCTAssertEqual(g.state.parked[.cap]?.state.parkedFactory?.level, 4, "Cappadocia keeps its four levels")
        g.state.cash = 100_000
        let cash = g.state.cash
        XCTAssertTrue(g.upgradeFactory())
        XCTAssertEqual(cash - g.state.cash, 30000, "the line is paid from the region's own cash box")
        XCTAssertEqual(g.state.factorySizes, [.S])
        // back home: Cappadocia's level 4, Albuquerque's 2 waits for you
        g.switchRegion(.cap)
        XCTAssertEqual(g.state.factoryLevel, 4)
        XCTAssertEqual(g.state.parked[.abq]?.state.parkedFactory?.level, 2)
        XCTAssertNil(g.state.local.parkedFactory, "the region you're in keeps its lines in `factory`")
        g.switchRegion(.abq)
        XCTAssertEqual(g.state.factoryLevel, 2)
        // and through a save
        let back = try reload(g)
        XCTAssertEqual(back.state.factoryLevel, 2)
        XCTAssertEqual(back.state.parked[.cap]?.state.parkedFactory?.level, 4)
        XCTAssertEqual(back.state, g.state)
    }

    func testBalloonOnTheLineFinishesInItsRegion() {
        var g = baron()
        XCTAssertTrue(g.enterRegion(.abq))
        g.switchRegion(.cap)
        let capN = g.state.balloons.count
        XCTAssertTrue(g.buildBalloon(.L))
        g.state.factory?.order = FactoryOrder(rival: "Göreme Sky", size: .M, price: 28000, until: g.state.day + 1)
        g.switchRegion(.abq)
        XCTAssertNil(g.state.factory?.job, "Albuquerque's line is free")
        XCTAssertNotNil(g.state.parked[.cap]?.state.parkedFactory?.job, "Cappadocia's balloon stays on Cappadocia's line")
        XCTAssertNil(g.state.parked[.cap]?.state.parkedFactory?.order, "an order is good for the day only")
        let abqN = g.state.balloons.count
        for _ in 0..<Rules.factoryDays(.L) { play(&g) }
        XCTAssertEqual(g.state.balloons.count, abqN, "not into Albuquerque's fleet")
        XCTAssertEqual(g.state.parked[.cap]?.state.balloons.count, capN + 1, "into Cappadocia's")
        XCTAssertEqual(g.state.parked[.cap]?.state.parkedFactory?.made, 1)
        XCTAssertNil(g.state.parked[.cap]?.state.parkedFactory?.job)
        XCTAssertEqual(Set(g.state.parked[.cap]!.state.balloons.map(\.name)).count, capN + 1, "a name of its own")
    }

    func testRivalOrderOnAParkedLineIsDeliveredThere() {
        var g = baron()
        XCTAssertTrue(g.enterRegion(.abq))
        g.switchRegion(.cap)
        g.state.factory?.order = FactoryOrder(rival: "Göreme Sky", size: .L, price: 36000, until: g.state.day + 1)
        XCTAssertTrue(g.acceptFactoryOrder())
        let rivalN = g.state.local.rivals.first { $0.name == "Göreme Sky" }!.balloons.count
        g.switchRegion(.abq)
        let capCash = g.state.parked[.cap]!.state.cash
        for _ in 0..<Rules.factoryDays(.L) { play(&g) }
        let cap = g.state.parked[.cap]!.state
        XCTAssertEqual(cap.rivals.first { $0.name == "Göreme Sky" }!.balloons.count, rivalN + 1)
        XCTAssertGreaterThanOrEqual(cap.cash - capCash, 36000 - 1, "paid into Cappadocia's cash box (plus its autopilot day)")
        XCTAssertEqual(cap.parkedFactory?.earned, 36000 - g.state.factoryCost(.L))
    }

    func testClosedRegionLosesItsLines() {
        var g = baron()
        g.state.ruinPending = g.state.day
        g.closeRegion()
        XCTAssertEqual(g.state.factoryLevel, 1, "the bank took the lines; the workshop and designs stay")
        XCTAssertNotNil(g.state.workshopDay)
    }

    // MARK: Older saves

    /// A save from before v142 playing in Albuquerque with the shared level-4 workshop: the level and the tally go to
    /// Cappadocia, Albuquerque starts at 1, the balloon on the line keeps going and comes out where it was started.
    func testOldSaveInAnotherRegionHandsTheLevelToCappadocia() throws {
        var g = baron()
        XCTAssertTrue(g.enterRegion(.abq))
        // what a v141 save looked like: one shared factory, nothing parked with Cappadocia
        var f = g.state.parked[.cap]!.state.parkedFactory!
        f.built = 9; f.made = 8; f.saved = 120_000
        f.job = FactoryJob(size: .M, done: g.state.day + 2, region: .abq, rival: nil, price: 0)
        g.state.factory = f
        g.state.parked[.cap]!.state.parkedFactory = nil
        var json = try XCTUnwrap(String(data: JSONEncoder().encode(g.state), encoding: .utf8))
        XCTAssertTrue(json.contains("\"factoryPerRegion\":true"))
        json = json.replacingOccurrences(of: "\"factoryPerRegion\":true,", with: "").replacingOccurrences(of: ",\"factoryPerRegion\":true", with: "")
        XCTAssertFalse(json.contains("factoryPerRegion"))
        var back = Game(state: try JSONDecoder().decode(GameState.self, from: Data(json.utf8)))
        XCTAssertEqual(back.state.factoryPerRegion, true)
        XCTAssertEqual(back.state.factoryLevel, 1, "Albuquerque starts at level 1")
        XCTAssertNotNil(back.state.factory?.job, "the balloon on the line keeps going")
        XCTAssertEqual(back.state.factory?.made, 0)
        let cf = try XCTUnwrap(back.state.parked[.cap]?.state.parkedFactory)
        XCTAssertEqual(cf.level, 4, "Cappadocia gets the old level")
        XCTAssertEqual(cf.made, 8, "and the tally")
        XCTAssertNil(cf.job)
        let n = back.state.balloons.count
        for _ in 0..<2 { play(&back) }
        XCTAssertEqual(back.state.balloons.count, n + 1, "the medium balloon joins Albuquerque's fleet as it would have")
        // a second load changes nothing
        let again = try reload(back)
        XCTAssertEqual(again.state.parked[.cap]?.state.parkedFactory?.level, 4)
        XCTAssertEqual(again.state.factoryLevel, 1)
    }

    /// An old save in Cappadocia keeps its workshop as it is; the regions it enters later start at level 1.
    func testOldSaveInCappadociaKeepsItsLevel() throws {
        var g = baron(level: 3)
        var json = try XCTUnwrap(String(data: JSONEncoder().encode(g.state), encoding: .utf8))
        json = json.replacingOccurrences(of: "\"factoryPerRegion\":true,", with: "").replacingOccurrences(of: ",\"factoryPerRegion\":true", with: "")
        g = Game(state: try JSONDecoder().decode(GameState.self, from: Data(json.utf8)))
        XCTAssertEqual(g.state.factoryLevel, 3)
        XCTAssertTrue(g.enterRegion(.abq))
        XCTAssertEqual(g.state.factoryLevel, 1)
        XCTAssertEqual(g.state.parked[.cap]?.state.parkedFactory?.level, 3)
    }
}
