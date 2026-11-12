import XCTest
@testable import BalloonBaronCore

/// QA v141: the whole campaign on the core, the bot of tools/sim-campaign.js in short: Cappadocia, Albuquerque, Luxor,
/// Bristol and the Maasai Mara (Grand Tour owned), the holding goals after Luxor's baron, World Baron. It checks the core
/// agrees with the prototype on the order of magnitude (prototype, 18 seeds: barons about 150 / 295 / 430 / 565 / 750,
/// World Baron about 650). Opt-in, it takes a while: `CAMPAIGN_SIM=1 swift test --filter CampaignSimTests`
/// (`CAMPAIGN_SEEDS=8` for more seeds).
final class CampaignSimTests: XCTestCase {
    struct Run { var enter: [RegionID: Int] = [:], baron: [RegionID: Int] = [:], world: Int?, end = 0, over = false, minCash = Int.max, weird: [String] = [], goals: [String: Int] = [:] }

    static let next: [RegionID: RegionID] = [.cap: .abq, .abq: .lux, .lux: .bri, .bri: .mara]

    func flight(_ g: Game, rng: inout SplitMix64) -> FlightResult {
        let mara = g.state.region == .mara, r = rng.unit()
        let q: FlightResult.Landing = mara && rng.chance(0.02) ? .crash : r < 0.3 ? .perfect : r < 0.85 ? .good : .far
        let m = g.state.weather?.mission
        var f = FlightResult(landing: q, distance: q == .far ? 400 : 60, mission: m, missionDone: m != nil && rng.chance(0.6))
        if mara { if q == .crash { f.river = true } else if rng.chance(0.08) { f.herd = .gnu } }
        return f
    }

    func play(seed: UInt64, maxDays: Int = 1400) -> Run {
        var g = Game(company: "Bot", colors: Rules.palettes[0], seed: seed)
        var rng = SplitMix64(seed: seed &* 7 &+ 3)
        g.grantStoreItem(.worldTour)
        g.skipTutorial()
        var run = Run()
        run.enter[.cap] = 1
        for _ in 0..<maxDays {
            if g.state.over { run.over = true; break }
            g.startDay()
            while g.nextHezarfen() != nil {}
            if g.state.transferAsk != nil { g.skipTransfer() }
            // as the prototype's bot: a problem in a region is waved away (sim-campaign.js clears `issue`)
            for r in g.state.parked.keys { g.state.parked[r]?.auto.issue = nil }
            g.state.local.openIssue = nil
            if g.state.eventDue == true, let e = g.drawMorningEvent() { _ = g.answerEvent(e, accept: false) }
            if let o = g.state.poach { g.answerPoach(match: o.wage <= 400) }
            if g.state.ruinPending != nil { if !g.acceptHoldingRescue() { g.closeRegion() } }
            if let o = g.state.local.contracts?.offer {
                let seats = g.state.local.balloons.reduce(0) { $0 + $1.size.capacity }
                let fog = o.fogP.map { $0.reduce(0, +) / Double(max(1, $0.count)) } ?? 0
                if Double(o.n) <= Double(seats) * 0.85 && fog <= 0.45 { g.acceptContract() } else { g.declineContract() }
            }
            _ = g.chooseContractDelay(.hold)
            let s0 = g.state
            // price: fill the baskets
            if let ls = s0.lastShare, ls.cap > 0 {
                let l = Double(ls.me) / Double(ls.cap)
                if l > 0.97 { g.setPrice(s0.price + 10) } else if l < 0.75 { g.setPrice(s0.price - 10) }
                g.setPrice(clamp(g.state.price, 100, 320))
            }
            // baron here: the money to the holding and on to the next region
            if g.state.isBaron(), let nx = Self.next[g.state.region], !g.state.owns(nx) {
                _ = g.withdraw(share: 1)
                if g.enterRegion(nx) { run.enter[nx] = g.state.day; g.skipTransfer(); if ProcessInfo.processInfo.environment["CAMPAIGN_DBG"] != nil { print("DBG", nx, g.state.day, g.state.holding.cash, g.state.parked.sorted { $0.key.rawValue < $1.key.rawValue }.map { "\($0.key.rawValue):\(Int($0.value.auto.base))/\($0.value.state.balloons.count)" }) }; continue }
            }
            // after Luxor: the holding goals
            if g.state.isBaron(.lux) {
                if g.state.isBaron() && g.state.cash > 30000 { _ = g.withdraw(share: 1) }
                for o in Office.listed where !g.state.holding.has(o) && g.canOpenOffice(o) { _ = g.openOffice(o) }
                _ = g.fundResearch()
                if g.state.holding.celebrity == nil { _ = g.signCelebrity() }
                if g.state.isBaron(.bri) && g.state.holding.worldGamesUntil == nil { _ = g.holdWorldGamesShow() }
                g.holdingGoalsNow()
            }
            let c = g.state.currentChapter
            func need(_ k: GoalKind) -> Bool { c?.goals.contains { $0.kind == k && !g.state.done($0) } ?? false }
            let saving = c != nil && !need(.seats) && (c?.goals.contains { !g.state.done($0) && [.factoryBuilt, .workshop, .xl, .school, .hotelOwn, .bldTop, .bldHangar, .bldMast].contains($0.kind) } ?? false) && g.state.cash < 250000
            if g.state.loans.isEmpty && g.state.balloons.count < 4 && g.state.cash < 15000 && (g.state.day >= 6 || g.state.region != .cap) { _ = g.takeLoan(0) }
            func room() -> Bool { g.state.balloons.count < g.state.hangarCapacity }
            func grow(_ buf: Int) { if let cost = Building.hangar.upgradeCost(from: g.state.level(.hangar)), g.state.cash > cost + buf { _ = g.upgrade(.hangar) } }
            // v142: the workshop as a player uses it, once it's founded: a free line builds the balloon at half price, the lines
            // are grown (per region since v142) when the cash allows, a rival's order is taken
            func buy(_ z: BalloonSize, _ buf: Int) {
                if !room() { grow(buf) } else if g.state.factoryCan(z) && !g.state.factoryBusy { _ = g.buildBalloon(z) } else { _ = g.buyBalloon(z) }
            }
            if g.state.factory?.order != nil && !g.state.factoryBusy { _ = g.acceptFactoryOrder() }
            // a line is grown for the size bought now (medium from 3 balloons, large from 14) while the balloons still to buy at
            // that size save more than the levels still cost, and only with cash to spare (twice the level's price + 40,000),
            // as `tools/sim-campaign.js` does (v142: saving up for it, or a smaller cushion, made the new regions slower)
            if g.state.workshopDay != nil && g.state.winter == nil && !saving && !g.state.isBaron() {
                let n = g.state.balloons.count, tgt = n >= 14 ? 4 : n >= 3 ? 3 : 0, z: BalloonSize = tgt == 4 ? .L : .M, lv = g.state.factoryLevel
                let rest = lv < tgt ? Rules.factoryLevelCost[(lv - 1)..<(tgt - 1)].reduce(0, +) : 0
                if tgt > 0, lv < tgt, let cost = g.state.factoryNextCost, ((tgt == 4 ? 45 : 14) - n) * (z.cost - g.state.factoryCost(z)) > rest,
                   g.state.cash > 2 * cost + 40000 { _ = g.upgradeFactory() }
            }
            if g.state.winter == nil && !saving && !g.state.isBaron() {
                let n = g.state.balloons.count
                if n < 3 && g.state.cash >= BalloonSize.S.cost + 1500 { buy(.S, 1500) }
                else if n >= 3 && n < 14 && g.state.cash > BalloonSize.M.cost + 15000 { buy(.M, 15000) }
                else if n >= 14 && n < 45 && g.state.cash > BalloonSize.L.cost + 30000 { buy(.L, 30000) }
            }
            while g.state.balloons.contains(where: { g.state.status($0) == .noPilot }), let p = g.state.candidates.min(by: { $0.level < $1.level }) { if !g.hire(p.id) { break } }
            for b in g.state.balloons where g.state.condition(b) <= 0 && g.state.cash > g.renewCost(b) + 3000 { g.renewEnvelope(b.id) }
            if g.state.hotelDeals.count < 2 {
                for h in Hotel.allCases where g.state.hotelDeals.count < 2 && g.state.cash > h.dailyFee * 3 + 4000 { _ = g.signHotel(h) }
            }
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
            if let e = run.enter[.abq], g.state.day - e == 30, ProcessInfo.processInfo.environment["CAMPAIGN_DBG"] != nil { print("DBG abq+30", g.state.day, g.state.holding.cash, g.state.holding.todayGross ?? -1, g.state.holding.todayCost ?? -1, g.state.parked[.cap]?.state.cash ?? -1, g.state.parked[.cap]?.auto.todayRaw ?? -1) }
            run.minCash = min(run.minCash, g.state.cash)
            if g.state.holding.cash < 0 { run.weird.append("holding<0 @\(g.state.day)") }
            for (r, d) in g.state.barons where run.baron[r] == nil { run.baron[r] = d }
            for k in HoldingGoal.allCases where run.goals[k.rawValue] == nil && g.state.done(k) { run.goals[k.rawValue] = g.state.day }
            if run.world == nil, let w = g.state.holding.worldBaron { run.world = w }
            if run.world != nil && g.state.isBaron(.mara) { break }
        }
        run.end = g.state.day
        return run
    }

    func testWholeCampaign() throws {
        guard ProcessInfo.processInfo.environment["CAMPAIGN_SIM"] != nil else { throw XCTSkip("opt-in: CAMPAIGN_SIM=1") }
        let n = Int(ProcessInfo.processInfo.environment["CAMPAIGN_SEEDS"] ?? "4") ?? 4
        var all: [Run] = []
        for seed in 1...UInt64(n) {
            let r = play(seed: seed)
            all.append(r)
            let b = RegionID.allCases.map { "\($0.rawValue) \(r.enter[$0].map(String.init) ?? "-")→\(r.baron[$0].map(String.init) ?? "-")" }.joined(separator: "  ")
            print("seed \(seed): \(b)  world \(r.world.map(String.init) ?? "-")  end \(r.end)  over \(r.over)  minCash \(r.minCash) \(r.weird.prefix(3))")
            XCTAssertFalse(r.over, "seed \(seed)")
            XCTAssertNotNil(r.baron[.mara], "seed \(seed): the Mara's baron")
            XCTAssertNotNil(r.world, "seed \(seed): World Baron")
        }
        func avg(_ f: (Run) -> Int?) -> String { let v = all.compactMap(f); return v.isEmpty ? "-" : "\(v.reduce(0, +) / v.count)" }
        print("holding goals, average day: " + HoldingGoal.allCases.map { k in "\(k.rawValue) \(avg { $0.goals[k.rawValue] })" }.joined(separator: " "))
        print("average barons: " + RegionID.allCases.map { r in "\(r.rawValue) \(avg { $0.baron[r] })" }.joined(separator: " ") + "  world \(avg { $0.world })")
    }
}
