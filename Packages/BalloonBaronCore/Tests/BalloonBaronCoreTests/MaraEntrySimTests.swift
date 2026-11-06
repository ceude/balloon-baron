import XCTest
@testable import BalloonBaronCore

/// QA v141.8 (TestFlight crash on entering the Mara from Bristol): the campaign bot plays to the Bristol baron with a
/// fleet in every region, then enters the Mara as the app does (skipping the transfer, bringing balloons and pilots, or
/// balloons only) and plays 120 days there. Opt-in, it takes about half a minute: `CAMPAIGN_SIM=1 swift test --filter
/// MaraEntrySimTests`. (The crash itself was in the app's town painter, `TownIdentity.swift`, not the core.)
final class MaraEntrySimTests: XCTestCase {
    func flight(_ g: Game, rng: inout SplitMix64) -> FlightResult {
        let mara = g.state.region == .mara, r = rng.unit()
        let q: FlightResult.Landing = mara && rng.chance(0.02) ? .crash : r < 0.3 ? .perfect : r < 0.85 ? .good : .far
        let m = g.state.weather?.mission
        var f = FlightResult(landing: q, distance: q == .far ? 400 : 60, mission: m, missionDone: m != nil && rng.chance(0.6))
        if mara { if q == .crash { f.river = true } else if rng.chance(0.08) { f.herd = .gnu } }
        return f
    }

    /// Plays the campaign bot until the Bristol baron, keeping each region's fleet (no withdrawal of everything).
    func playToBristolBaron(seed: UInt64, accept: Bool) -> Game? {
        var g = Game(company: "Bot", colors: Rules.palettes[0], seed: seed)
        var rng = SplitMix64(seed: seed &* 7 &+ 3)
        g.grantStoreItem(.worldTour)
        g.skipTutorial()
        for _ in 0..<1400 {
            if g.state.over { return nil }
            g.startDay()
            while g.nextHezarfen() != nil {}
            if g.state.transferAsk != nil {
                if accept { let d = g.transferDefaults; g.applyTransfer(balloons: d.balloons, pilots: d.pilots) } else { g.skipTransfer() }
            }
            for r in g.state.parked.keys { g.state.parked[r]?.auto.issue = nil }
            g.state.local.openIssue = nil
            if g.state.eventDue == true, let e = g.drawMorningEvent() { _ = g.answerEvent(e, accept: false) }
            if let o = g.state.poach { g.answerPoach(match: o.wage <= 400) }
            if g.state.ruinPending != nil { if !g.acceptHoldingRescue() { g.closeRegion() } }
            if let o = g.state.local.contracts?.offer {
                let seats = g.state.local.balloons.reduce(0) { $0 + $1.size.capacity }
                if Double(o.n) <= Double(seats) * 0.85 { g.acceptContract() } else { g.declineContract() }
            }
            _ = g.chooseContractDelay(.hold)
            if g.state.isBaron(.bri) && g.state.region == .bri { return g }
            if g.state.isBaron(), let nx = CampaignSimTests.next[g.state.region], !g.state.owns(nx) {
                _ = g.withdraw(share: 0.8)
                if g.enterRegion(nx) {
                    if accept { let d = g.transferDefaults; g.applyTransfer(balloons: d.balloons, pilots: d.pilots) } else { g.skipTransfer() }
                    continue
                }
            }
            if g.state.isBaron(.lux) {
                for o in Office.listed where !g.state.holding.has(o) && g.canOpenOffice(o) { _ = g.openOffice(o) }
                _ = g.fundResearch()
                if g.state.holding.celebrity == nil { _ = g.signCelebrity() }
                g.holdingGoalsNow()
            }
            let c = g.state.currentChapter
            func need(_ k: GoalKind) -> Bool { c?.goals.contains { $0.kind == k && !g.state.done($0) } ?? false }
            if g.state.loans.isEmpty && g.state.balloons.count < 4 && g.state.cash < 15000 && (g.state.day >= 6 || g.state.region != .cap) { _ = g.takeLoan(0) }
            func room() -> Bool { g.state.balloons.count < g.state.hangarCapacity }
            func grow(_ buf: Int) { if let cost = Building.hangar.upgradeCost(from: g.state.level(.hangar)), g.state.cash > cost + buf { _ = g.upgrade(.hangar) } }
            func buy(_ z: BalloonSize, _ buf: Int) { if room() { _ = g.buyBalloon(z) } else { grow(buf) } }
            if g.state.winter == nil && !g.state.isBaron() {
                let n = g.state.balloons.count
                if n < 3 && g.state.cash >= BalloonSize.S.cost + 1500 { buy(.S, 1500) }
                else if n >= 3 && n < 14 && g.state.cash > BalloonSize.M.cost + 15000 { buy(.M, 15000) }
                else if n >= 14 && n < 45 && g.state.cash > BalloonSize.L.cost + 30000 { buy(.L, 30000) }
            }
            while g.state.balloons.contains(where: { g.state.status($0) == .noPilot }), let p = g.state.candidates.min(by: { $0.level < $1.level }) { if !g.hire(p.id) { break } }
            for b in g.state.balloons where g.state.condition(b) <= 0 && g.state.cash > g.renewCost(b) + 3000 { g.renewEnvelope(b.id) }
            if g.state.hotelDeals.count < 2 { for h in Hotel.allCases where g.state.hotelDeals.count < 2 && g.state.cash > h.dailyFee * 3 + 4000 { _ = g.signHotel(h) } }
            if g.state.cash > 6000 { _ = g.runGuideFlight() }
            if need(.glow) { _ = g.bookGlow() }
            if (need(.influencer) || need(.stars)) && g.state.cash > g.state.influencerCost * 2 + 5000 { _ = g.runInfluencer() }
            if need(.hotelOwn) { for h in Hotel.allCases where g.state.cash > h.buyPrice + 20000 { if g.buyHotel(h) { break } } }
            if (need(.workshop) || need(.factoryBuilt)) && g.state.workshopDay == nil && g.state.cash > Studio.workshopCost + 20000 { _ = g.buildWorkshop() }
            if need(.factoryBuilt) && g.state.workshopDay != nil { if !g.upgradeFactory() { _ = g.buildBalloon(.S) } }
            if need(.school) && g.state.cash > Rules.schoolCost + 20000 { _ = g.buildSchool() }
            if need(.xl) && g.state.cash > 170000 { if room() { _ = g.buyBalloon(.XL) } else { grow(170000) } }
            func up(_ b: Building, _ buf: Int) { if let cost = b.upgradeCost(from: g.state.level(b)), g.state.cash > cost + buf { _ = g.upgrade(b) } }
            if need(.bldMast) { up(.mast, 5000) }
            if need(.bldHangar) { up(.hangar, 10000) }
            if need(.bldTop) { up(.mast, 10000) }
            g.setSelfFly(true)
            let red = g.state.weather?.flag == .red
            if g.launch(skip: red) != nil { _ = g.finishDay(flight: flight(g, rng: &rng)) } else { _ = g.finishDay(flight: nil) }
        }
        return nil
    }

    /// What `GameStore.act` does around an action, plus the transfer card's reads.
    func appEnter(_ g: inout Game, _ r: RegionID) {
        g.state.holding.cash = max(g.state.holding.cash, r.entryFee + 10)
        XCTAssertTrue(g.canEnterRegion(r))
        XCTAssertTrue(g.enterRegion(r))
        g.holdingGoalsNow()
        _ = g.finishChapterNow()
        _ = g.transferBalloons; _ = g.transferPilots
        let d = g.transferDefaults
        for x in RegionID.allCases { _ = g.transferIncome(x, balloons: d.balloons, pilots: d.pilots) }
        _ = g.transferCost(balloons: d.balloons)
    }

    func testEnterMaraFromARealBristol() throws {
        guard ProcessInfo.processInfo.environment["CAMPAIGN_SIM"] != nil else { throw XCTSkip("opt-in") }
        for seed in UInt64(1)...4 {
            for accept in [false, true] {
                guard let base = playToBristolBaron(seed: seed, accept: accept) else { XCTFail("no bristol \(seed)"); continue }
                print("seed", seed, accept, "day", base.state.day, "balloons", base.state.balloons.count, "parked", base.state.parked.mapValues { $0.state.balloons.count })
                for mode in 0..<3 {
                    var g = base
                    appEnter(&g, .mara)
                    while g.nextHezarfen() != nil {}
                    if mode == 0 { g.skipTransfer() } else { let d = g.transferDefaults; g.applyTransfer(balloons: d.balloons, pilots: mode == 1 ? d.pilots : []) }
                    var rng = SplitMix64(seed: seed)
                                for _ in 0..<120 {
                        g.startDay()
                        while g.nextHezarfen() != nil {}
                        if g.state.eventDue == true, let e = g.drawMorningEvent() { _ = g.answerEvent(e, accept: true) }
                        g.setSelfFly(true)
                        if g.launch(skip: g.state.weather?.flag == .red) != nil { _ = g.finishDay(flight: flight(g, rng: &rng)) } else { _ = g.finishDay(flight: nil) }
                        g.holdingGoalsNow(); _ = g.finishChapterNow()
                    }
                }
            }
        }
    }
}
