import XCTest
@testable import BalloonBaronCore

/// v131: fixes from a four-hour TestFlight session: the purchase loan says why it can't be used, contract income and
/// show refunds are lines in the day's money table that add up to the cash change, and a region can keep its
/// autopilot profit instead of sending it to the holding.
final class TesterFixesTests: XCTestCase {
    func game(seed: UInt64 = 42) -> Game {
        var g = Game(company: "Test Air", colors: Rules.palettes[0], seed: seed)
        g.state.tutorial = TutorialState(done: true)
        g.startDay()
        return g
    }

    // MARK: Purchase loan

    /// A company the purchase loan can serve: bank open, 10 balloons, the 100,000 loan opened, no loans.
    func loanReady() -> Game {
        var g = game()
        g.state.unlocked.insert(.bank)
        g.state.local.balloons = (0..<10).map { Balloon(id: 500 + $0, size: .M, name: "B\($0)") }
        g.state.local.loansOpen = [100_000]
        g.state.loans = []
        g.state.cash = 200_000
        return g
    }

    func testPurchaseLoanOpenWhenEverythingHolds() {
        let g = loanReady()
        XCTAssertNil(g.buyLoanBlock(price: 600_000))
        XCTAssertEqual(g.buyLoanTerms(price: 600_000)?.financed, 410_000)
        XCTAssertEqual(g.buyLoanBlocks(price: 150_000), [.cashEnough])
    }

    func testPurchaseLoanSaysWhatBlocksIt() {
        var g = loanReady()
        XCTAssertEqual(g.buyLoanBlocks(price: 800_000), [.tooBig(more: 110_000)], "the bank pays at most 500,000")
        XCTAssertEqual(g.buyLoanBlocks(price: 1_000_000), [.tooBig(more: 310_000), .lowDown(more: 10_000)])
        g.state.local.loansOpen = nil
        g.state.local.netHistory = [8000, 9000, 9500, 9000, 8800, 9100, 9900, 12000]
        XCTAssertEqual(g.buyLoanBlocks(price: 600_000), [.notOpen(net: 9100, need: 10000, days: 8)],
                       "with no loan at all, the 100,000 loan still has to open: a typical day of 10,000 here")
        g.state.local.loansOpen = [100_000]
        g.state.loans = [Loan(amount: 100_000, installment: 1500, daysLeft: 20, purchase: true)]
        XCTAssertEqual(g.buyLoanBlocks(price: 600_000), [.purchaseLoanRunning])
        g.state.loans = [Loan(amount: 10000, installment: 300, daysLeft: 20), Loan(amount: 25000, installment: 650, daysLeft: 20)]
        XCTAssertEqual(g.buyLoanBlocks(price: 600_000), [.loansFull])
        g.state.loans = []
        g.state.local.balloons.removeLast(3)
        XCTAssertEqual(g.buyLoanBlocks(price: 600_000), [.fewBalloons(have: 7, need: 10)])
        g.state.unlocked.remove(.bank)
        XCTAssertEqual(g.buyLoanBlocks(price: 600_000), [.noBank])
    }

    /// The 100,000 loan opens per region: a new region starts closed, the one left behind keeps it.
    func testTheBigLoanOpensPerRegion() {
        var g = loanReady()
        g.state.chapter = 4
        g.state.barons[.cap] = 1
        g.grantStoreItem(.worldTour)
        g.state.holding.cash = 200_000
        XCTAssertTrue(g.enterRegion(.abq))
        XCTAssertEqual(g.state.parked[.cap]?.state.loansOpen, [100_000])
        g.state.unlocked.insert(.bank)
        g.state.local.balloons = (0..<10).map { Balloon(id: 900 + $0, size: .M, name: "A\($0)") }
        g.state.cash = 200_000
        if case .notOpen = g.buyLoanBlock(price: 600_000) {} else { XCTFail("Albuquerque opens its own 100,000 loan") }
    }

    // MARK: The day's money table

    func capWithCharter(price: Int = 150, n: Int = 14) -> (Game, ContractJob) {
        var g = game()
        g.state.day = 45
        g.state.local.chapter = 1
        g.state.local.balloons = []
        g.state.local.pilots = []
        for (i, z) in [BalloonSize.M, .M, .M, .M].enumerated() {
            g.state.local.balloons.append(Balloon(id: g.state.nextID, size: z, name: "B\(i)"))
            g.state.local.pilots.append(Pilot(id: g.state.nextID + 1000, name: "P\(i)", level: .experienced))
            g.state.nextID += 1
        }
        g.state.local.flagship = g.state.local.balloons[0].id
        g.state.local.selfFly = false
        g.state.lastSelfFly = g.state.day
        g.state.cash = 100_000
        g.state.local.winter = nil
        g.state.weather?.flag = .green
        g.state.weather?.fog = nil
        g.assignPilots()
        var c = g.state.local.contracts ?? ContractState()
        let k = ContractJob(id: g.state.nextID, owner: .jiwoo, n: n, price: price, day: g.state.day, len: 2, fogP: nil)
        g.state.nextID += 1
        c.booked.append(k)
        c.next = g.state.day + 100
        g.state.local.contracts = c
        return (g, k)
    }

    func testCharterIncomeIsALineAndReachesTheCash() {
        var (g, _) = capWithCharter()
        let cash0 = g.state.cash
        _ = g.launch()
        let r = g.finishDay(flight: nil)
        XCTAssertEqual(r.ledger.contract, 14 * 150, "the group's pay is its own line")
        XCTAssertEqual(r.ledger.contractN, 14)
        XCTAssertEqual(r.ledger.contractFrom, ContractOwner.jiwoo.company)
        XCTAssertTrue(r.events.contains(.contractFlown(company: ContractOwner.jiwoo.company, dayN: 1, len: 2, n: 14, price: 150, total: 2100)),
                      "the event at the bottom gives the same total")
        XCTAssertEqual(g.state.cash - cash0, r.net, "the report's net is the day's cash change")
    }

    func testContractDaysAddUpOverSeveralDays() {
        for seed in UInt64(1)...6 {
            var (g, _) = capWithCharter(price: 140 + Int(seed) * 5, n: 10 + Int(seed))
            for _ in 0..<3 {
                g.startDay()
                while g.nextHezarfen() != nil {}
                let cash0 = g.state.cash
                _ = g.launch()
                let r = g.finishDay(flight: nil)
                XCTAssertEqual(g.state.cash - cash0, r.net, "seed \(seed) day \(r.day)")
            }
        }
    }

    func testShowRefundIsALine() {
        var g = game()
        g.state.local.showTonight = g.state.day
        g.state.local.showIDs = [g.state.local.balloons[0].id, 9991, 9992]
        let cash0 = g.state.cash
        _ = g.launch(skip: true)
        let r = g.finishDay(flight: nil)
        XCTAssertEqual(r.ledger.showRefund, Rules.showPerBalloon, "the flagship's fee comes back when the show is called off")
        XCTAssertEqual(g.state.cash - cash0, r.net)
    }

    // MARK: Holding: keep a region's money

    func parkedCap() -> Game {
        var g = game()
        g.state.chapter = 4
        g.state.barons[.cap] = 1
        g.grantStoreItem(.worldTour)
        g.state.local.netHistory = [20000, 22000, 24000]
        g.state.holding.cash = 200_000
        g.state.cash = 50_000
        XCTAssertTrue(g.enterRegion(.abq))
        return g
    }

    func testRegionsSendByDefault() throws {
        var g = parkedCap()
        XCTAssertTrue(g.state.holding.sends(.cap))
        let h0 = g.state.holding.cash, c0 = try XCTUnwrap(g.state.parked[.cap]).state.cash
        g.runAutopilots()
        let net = g.holdingDay()
        XCTAssertGreaterThan(net, 0)
        XCTAssertGreaterThan(g.state.holding.cash, h0)
        XCTAssertEqual(g.state.parked[.cap]?.state.cash, c0)
    }

    func testAKeptRegionFillsItsOwnCashBox() throws {
        var g = parkedCap()
        g.setSendsToHolding(.cap, false)
        XCTAssertEqual(g.state.holding.keepIn, [.cap])
        let h0 = g.state.holding.cash, c0 = try XCTUnwrap(g.state.parked[.cap]).state.cash
        g.runAutopilots()
        let raw = try XCTUnwrap(g.state.parked[.cap]).auto.todayRaw
        let net = g.holdingDay()
        XCTAssertEqual(net, 0, "nothing reaches the holding")
        XCTAssertEqual(g.state.holding.cash, h0)
        let kept = try XCTUnwrap(g.state.parked[.cap]?.auto.kept)
        XCTAssertEqual(kept, jsRound(Double(jsRound(raw * g.holdingBoost(.cap) * g.state.holding.officeMultiplier(.cap))) * 0.75),
                       "the same net as the holding would get: its running costs still apply")
        XCTAssertEqual(g.state.parked[.cap]?.state.cash, c0 + kept)
        // moved by hand later
        let moved = g.withdraw(from: .cap, share: 1)
        XCTAssertEqual(moved, c0 + kept - Holding.withdrawKeep)
        XCTAssertEqual(g.state.parked[.cap]?.state.cash, Holding.withdrawKeep)
        XCTAssertEqual(g.state.holding.cash, h0 + moved)
        // back on
        g.setSendsToHolding(.cap, true)
        XCTAssertNil(g.state.holding.keepIn)
    }

    func testOldSavesSendEverything() throws {
        var g = parkedCap()
        g.setSendsToHolding(.cap, false)
        var json = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(g.state.holding)) as? [String: Any])
        XCTAssertNotNil(json["keepIn"])
        json.removeValue(forKey: "keepIn")
        let back = try JSONDecoder().decode(Holding.self, from: JSONSerialization.data(withJSONObject: json))
        XCTAssertTrue(back.sends(.cap))
    }
}
