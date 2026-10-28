import XCTest
@testable import BalloonBaronCore

final class GameTests: XCTestCase {
    func newGame(seed: UInt64 = 42) -> Game {
        var g = Game(company: "Test Air", colors: Rules.palettes[0], seed: seed)
        g.startDay()
        return g
    }

    /// Plays one day; the player lands well whenever they fly themselves.
    @discardableResult
    func play(_ g: inout Game, landing: FlightResult.Landing = .good, skipRed: Bool = false) -> DayReport {
        g.startDay()
        while g.nextHezarfen() != nil {}
        if g.launch(skip: skipRed && g.state.weather?.flag == .red) != nil {
            let m = g.state.weather?.mission
            return g.finishDay(flight: FlightResult(landing: landing, distance: 120, mission: m, missionDone: m != nil))
        }
        return g.finishDay(flight: nil)
    }

    func testNewGame() {
        let g = newGame()
        XCTAssertEqual(g.state.cash, 3000)
        XCTAssertEqual(g.state.balloons.count, 1)
        XCTAssertEqual(g.state.balloons[0].size, .S)
        XCTAssertEqual(g.state.weather?.flag, .green, "day 1 is always green")
        XCTAssertNil(g.state.weather?.mission)
        XCTAssertEqual(g.state.rivals.count, 3)
        XCTAssertEqual(g.state.stars, 4, accuracy: 0.001)
        XCTAssertEqual(g.state.hezQueue.first, .tip(.welcome))
    }

    func testAllocateRespectsCapacityAndDemand() {
        let comps = [Competitor(price: 170, rep: 1, cap: 8), Competitor(price: 195, rep: 1.15, cap: 80),
                     Competitor(price: 135, rep: 0.85, cap: 16)]
        let pax = Market.allocate(comps, tourists: 165)
        for (p, c) in zip(pax, comps) { XCTAssertLessThanOrEqual(p, c.cap) }
        XCTAssertLessThanOrEqual(pax.reduce(0, +), 165)
        XCTAssertEqual(pax[0], 8, "a small newcomer at a fair price fills up")
    }

    func testCrisisAndPriceHurtShare() {
        let fair = Market.allocate([Competitor(price: 170, rep: 1, cap: 500), Competitor(price: 170, rep: 1, cap: 500)], tourists: 200)
        let crisis = Market.allocate([Competitor(price: 170, rep: 0.45, cap: 500), Competitor(price: 170, rep: 1, cap: 500)], tourists: 200)
        let pricey = Market.allocate([Competitor(price: 320, rep: 1, cap: 500), Competitor(price: 170, rep: 1, cap: 500)], tourists: 200)
        XCTAssertGreaterThan(fair[0], crisis[0] * 3)
        XCTAssertGreaterThan(fair[0], pricey[0] * 3)
    }

    func testFirstDayEconomy() {
        var g = newGame()
        let cash = g.state.cash
        XCTAssertLessThan(g.market(price: 170, capacity: 8).pax[0], 8, "rivals' fleets leave a newcomer short at the default price")
        g.setPrice(150)
        let pax = g.launch()
        XCTAssertEqual(pax, 8, "a price cut fills the basket")
        let r = g.finishDay(flight: FlightResult(landing: .perfect, distance: 30))
        XCTAssertEqual(r.ledger.tickets, 8 * 150)
        XCTAssertEqual(r.ledger.founderBonus, 8 * 150 / 4, "passengers pay extra to fly with the founder")
        XCTAssertEqual(r.ledger.tips, 8 * 15)
        XCTAssertEqual(g.state.cash, cash + r.net)
        XCTAssertEqual(g.state.day, 2)
        XCTAssertNotNil(g.state.weather)
        XCTAssertTrue(g.state.reviews.contains { $0.kind == .perfect })
    }

    func testProposalIsFirstMission() {
        var g = newGame(seed: 7)
        var seen: Mission?
        for _ in 0..<15 {
            if let m = g.state.weather?.mission { seen = m; break }
            play(&g)
        }
        XCTAssertEqual(seen, .proposal)
        XCTAssertGreaterThanOrEqual(g.state.day, 3)
    }

    func testMissionRewardSurvivesHardLanding() {
        var g = newGame()
        g.launch()
        let r = g.finishDay(flight: FlightResult(landing: .hard, mission: .proposal, missionDone: true))
        XCTAssertEqual(r.ledger.mission, 450)

        var big = newGame()
        big.state.balloons[0].size = .M
        big.launch()
        let r2 = big.finishDay(flight: FlightResult(landing: .good, mission: .proposal, missionDone: true))
        XCTAssertEqual(r2.ledger.mission, 900, "a medium basket doubles the reward")
        XCTAssertGreaterThan(r.ledger.repairs, 0)
        XCTAssertTrue(r.events.contains(.missionDone(.proposal, reward: 450)))
    }

    func testCancelPaysCompensation() {
        var g = newGame()
        let pax = g.launch()!
        let r = g.finishDay(flight: FlightResult(landing: .cancel))
        XCTAssertEqual(r.ledger.cancellations, pax * Rules.cancelCompensation)
        XCTAssertEqual(r.ledger.tickets, 0)
        XCTAssertEqual(r.passengers, 0)
    }

    func testActions() {
        var g = newGame()
        XCTAssertFalse(g.buyBalloon(.M), "not enough cash")
        XCTAssertTrue(g.takeLoan(0))
        XCTAssertFalse(g.takeLoan(1), "needs two balloons")
        g.state.cash = 100_000
        XCTAssertTrue(g.buyBalloon(.M))
        XCTAssertEqual(g.state.balloons.last?.name, "Güvercin")
        XCTAssertEqual(g.state.status(g.state.balloons[1]), .noPilot)
        let c = g.state.candidates[0].id
        XCTAssertTrue(g.hire(c))
        XCTAssertEqual(g.state.status(g.state.balloons[1]), .ok)
        XCTAssertFalse(g.setAd(g.state.balloons[0].id, .energy), "energy sponsor needs a large basket")
        XCTAssertTrue(g.setAd(g.state.balloons[1].id, .wine))
        g.setPrice(999)
        XCTAssertEqual(g.state.price, 320)
        XCTAssertTrue(g.buyBalloon(.XL) == false, "cash too low for XL")
        g.state.cash = 400_000
        XCTAssertTrue(g.buyBalloon(.XL))
        XCTAssertFalse(g.buyBalloon(.XL), "only one signature balloon")
        XCTAssertTrue(g.sellBalloon(g.state.balloons[1].id))
    }

    func testExpiredLicenseGroundsFleetUntilYouFly() {
        var g = newGame()
        g.state.cash = 100_000
        g.buyBalloon(.M)
        g.hire(g.state.candidates[0].id)
        g.setSelfFly(false)
        g.state.lastSelfFly = g.state.day - 16
        g.assignPilots()
        XCTAssertFalse(g.state.licenseValid)
        let other = g.state.balloons[1]
        XCTAssertEqual(g.state.status(other), .licenseHold, "other balloons wait for the license")
        XCTAssertTrue(g.state.isSelf(g.state.balloons[0]), "you must fly the flagship yourself")
        XCTAssertEqual(g.state.status(g.state.balloons[0]), .ok)
        XCTAssertNotNil(g.launch())
        let r = g.finishDay(flight: FlightResult(landing: .good))
        XCTAssertTrue(r.events.contains(.licenseRenewedByFlight))
        XCTAssertTrue(g.state.licenseValid)
        XCTAssertEqual(g.state.status(g.state.balloons[1]), .ok)
    }

    func testPayingRenewsLicense() {
        var g = newGame()
        g.state.lastSelfFly = g.state.day - 16
        g.state.cash = 20000
        XCTAssertTrue(g.renewLicense())
        XCTAssertTrue(g.state.licenseValid)
        XCTAssertEqual(g.state.cash, 5000)
        XCTAssertTrue(g.state.selfFly, "no pilot for the flagship: you still fly it")
        var h = newGame()
        h.state.pilots.append(Pilot(id: 900, name: "Ali Kaya", level: .rookie))
        h.state.lastSelfFly = h.state.day - 16
        h.state.cash = 20000
        XCTAssertTrue(h.renewLicense())
        XCTAssertFalse(h.state.selfFly, "who pays rather than flies is offered pilots-only")
        XCTAssertEqual(h.state.flyingToday.count, 1, "and the flagship still flies, with the pilot")
    }

    func testPopularityErodesWithoutTheFounder() {
        // Two identical companies run by pilots; in one the founder is counted as flying recently.
        func run(present: Bool) -> (rep: Double, absentEvent: Bool, tip: Bool) {
            var g = newGame()
            g.state.cash = 100_000
            g.buyBalloon(.S)
            for c in g.state.candidates.prefix(2) { g.hire(c.id) }
            g.setSelfFly(false)
            var absentEvent = false
            for _ in 0..<9 {
                g.startDay()
                if present { g.state.lastSelfFly = g.state.day }
                g.launch(skip: g.state.weather?.flag == .red)
                let r = g.finishDay(flight: nil)
                if r.events.contains(where: { if case .founderAbsent = $0 { true } else { false } }) { absentEvent = true }
            }
            return (g.state.rep, absentEvent, g.state.tipsSeen.contains(.absent) || (g.state.hezQueue + (g.state.hezLater ?? [])).contains(.tip(.absent)))
        }
        let away = run(present: false), here = run(present: true)
        XCTAssertTrue(away.absentEvent)
        XCTAssertTrue(away.tip)
        XCTAssertFalse(here.absentEvent)
        XCTAssertLessThan(away.rep, here.rep, "popularity falls once the founder stays away")
    }

    /// Someone who never flies unless forced should end up far behind someone who flies daily.
    func testFlyingYourselfPaysOff() {
        func worth(passive: Bool, seed: UInt64) -> Int {
            var g = newGame(seed: seed)
            for _ in 0..<40 {
                g.startDay()
                while g.nextHezarfen() != nil {}
                if passive { g.setSelfFly(false) }
                while g.state.balloons.contains(where: { g.state.status($0) == .noPilot }), let c = g.state.candidates.first { g.hire(c.id) }
                g.setPrice(160)
                if g.launch(skip: g.state.weather?.flag == .red) != nil {
                    let m = g.state.weather?.mission
                    g.finishDay(flight: FlightResult(landing: passive ? .far : .good, distance: 300, mission: m, missionDone: !passive && m != nil))
                } else {
                    g.finishDay(flight: nil)
                }
                if g.state.cash > 25000 { g.buyBalloon(.S) }
                if g.state.poach != nil { g.answerPoach(match: true) }
            }
            return g.state.cash + g.state.balloons.reduce(0) { $0 + $1.size.cost } / 2
        }
        for seed: UInt64 in 1...3 {
            let a = worth(passive: false, seed: seed), p = worth(passive: true, seed: seed)
            XCTAssertGreaterThan(Double(a), Double(p) * 1.5, "seed \(seed): active \(a) vs passive \(p)")
        }
    }

    func testPopularityCap() {
        var g = newGame()
        g.state.unlocked.insert(.market) // the cap starts with the market (hotels, guides)
        g.state.rep = 1.3
        g.launch(skip: true)
        g.finishDay(flight: nil)
        XCTAssertEqual(g.state.rep, Rules.prCap, accuracy: 1e-9, "no hotel or guide: popularity stops at 4.2★")
        XCTAssertTrue(g.state.hezQueue.contains(.tip(.prcap)))
        g.startDay()
        g.state.rep = 1.3
        g.state.influencerCooldown = g.state.day + 5
        g.launch(skip: true)
        g.finishDay(flight: nil)
        XCTAssertEqual(g.state.rep, Rules.prCapInfluencer, accuracy: 1e-9, "a fresh influencer campaign stretches it to 4.5★")
        g.startDay()
        g.state.rep = 1.3
        g.state.lastGuide = g.state.day - 3
        g.launch(skip: true)
        g.finishDay(flight: nil)
        XCTAssertGreaterThan(g.state.rep, Rules.prCapInfluencer, "a recent guide flight lifts the cap")
    }

    func testSaveRoundTrip() throws {
        var g = newGame()
        for _ in 0..<10 { play(&g) }
        let data = try JSONEncoder().encode(g.state)
        let back = try JSONDecoder().decode(GameState.self, from: data)
        XCTAssertEqual(back, g.state)
    }

    /// Plays like a sensible player for 80 days: skips red days, grows the fleet, staffs it,
    /// signs hotels once there are seats to fill.
    func testLongRunIsStable() {
        let trace = ProcessInfo.processInfo.environment["TRACE"] != nil
        for seed: UInt64 in [1, 2, 3, 4, 5] {
            var g = newGame(seed: seed)
            var winterSeen = false, couldWinter = false
            for _ in 0..<80 {
                let before = g.state.cash
                let r = play(&g, skipRed: true)
                if r.ledger.antitrust == 0 && r.ledger.seizure == 0 {
                    XCTAssertEqual(g.state.cash - before, r.net, "ledger must explain every euro")
                }
                if trace && seed == 1 {
                    print("d\(r.day) \(r.flag) pax \(r.passengers)/\(r.capacity) net \(r.net) cash \(g.state.cash) n \(g.state.balloons.count) ★\(g.state.stars) \(r.events)")
                }
                XCTAssertLessThan(g.state.rep, 1.45)
                for rv in g.state.rivals { XCTAssertTrue((40...320).contains(rv.price), "\(rv.name) price \(rv.price)") }
                if g.state.winter != nil { winterSeen = true }
                if g.state.day >= 40 && g.state.cash >= 50000 { couldWinter = true }
                if g.state.winter == nil && g.state.balloons.count < 12 {
                    if g.state.cash > 60000 { g.buyBalloon(.M) } else if g.state.cash > 25000 { g.buyBalloon(.S) }
                }
                while g.state.balloons.contains(where: { g.state.status($0) == .noPilot }), let c = g.state.candidates.first {
                    g.hire(c.id)
                }
                if g.state.balloons.count >= 5 && g.state.cash > 20000 {
                    for h in Hotel.allCases { g.signHotel(h) }
                }
                if g.state.poach != nil { g.answerPoach(match: true) }
            }
            print("seed \(seed): day \(g.state.day) cash \(g.state.cash) balloons \(g.state.balloons.count) stars \(g.state.stars) rivals alive \(g.state.rivals.filter(\.alive).map(\.name))")
            XCTAssertFalse(g.state.over)
            XCTAssertGreaterThan(g.state.balloons.count, 3, "seed \(seed): the company should grow")
            // Winter comes once a company has €50,000 after day 40; one that keeps reinvesting may never get there.
            XCTAssertTrue(winterSeen || !couldWinter, "seed \(seed): winter should arrive by day 80")
        }
    }
}
