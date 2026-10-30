import Foundation

/// City offices of the holding. Perks stack; all four cut holding expenses.
public enum Office: String, Codable, CaseIterable, CodingKeyRepresentable, Sendable {
    case ist, nyc, sel, tyo

    public var cost: Int { [350000, 450000, 400000, 400000][index] }
    private var index: Int { Self.allCases.firstIndex(of: self)! }
}

public struct Celebrity: Codable, Equatable, Sendable {
    /// Index into the app's list of made-up stars (`celebrity.<n>`).
    public var index: Int
    public var until: Int
}

/// The company's euro wallet. It never sends money back to a region.
public struct Holding: Codable, Equatable, Sendable {
    public struct Day: Codable, Equatable, Sendable { public var day: Int, income: Int, expense: Int }
    public struct ResearchLevel: Sendable { public let cost: Int, life: Int }

    public static let expenseRate = 0.25
    public static let allOfficesExpenseRate = 0.2
    public static let entryFee = 100000
    /// Share of a parked region's typical profit its manager delivers.
    public static let autopilotEfficiency = 0.85
    public static let tvCost = 250000, tvDays = 14, tvCooldown = 30
    public static let celebrityCost = 600000, celebrityDays = 90, celebrityCount = 6
    public static let billboardCost = 120000, billboardDays = 20
    /// v122.7 (`JERSEY`, `WGAMES`): the league champion's jersey (no team named, the game is played worldwide), and the
    /// balloon show at the World Games' opening ceremony, once.
    public static let jerseyCost = 3_000_000, jerseyDays = 180, jerseyBoost = 1.15, jerseyRep = 0.1
    public static let worldGamesCost = 10_000_000, worldGamesDays = 60, worldGamesBoost = 1.3, worldGamesRep = 0.2
    public static let researchLevels = [ResearchLevel(cost: 400000, life: 160), ResearchLevel(cost: 900000, life: 200)]
    /// What you leave in a region's cash box when you take "all".
    public static let withdrawKeep = 10000

    public var cash = 0
    /// Last 30 days of income and expenses.
    public var history: [Day] = []
    /// Yesterday's autopilot income and expenses.
    public var todayGross = 0, todayCost = 0
    public var tvUntil = 0, tvCooldown = 0
    public var celebrity: Celebrity?
    public var billboards: [RegionID: Int] = [:]
    public var research = 0
    /// Day each office opened.
    public var offices: [Office: Int] = [:]
    // Added in version 3.
    public var tvCount: Int?
    /// Day the holding's six goals were all met.
    public var worldBaron: Int?
    // Added with Luxor.
    /// A record attempt being prepared, the day each record was set, and the lasting demand boost they earned.
    public var record: RecordRun?
    public var records: [RecordAttempt: Int]?
    public var recordBoost: Double?
    /// A brand's shaped balloon flying over a region for money.
    public var adShape: AdContract?
    // Added in v122.7.
    /// The jersey deal runs until this day; the World Games show was held, and its effect lasts until this day.
    public var jerseyUntil: Int?
    public var worldGamesUntil: Int?

    public func has(_ o: Office) -> Bool { offices[o] != nil }
    public var expenseRate: Double { offices.count == Office.allCases.count ? Self.allOfficesExpenseRate : Self.expenseRate }
    public var tvCost: Int { jsRound(Double(Self.tvCost) * (has(.nyc) ? 0.75 : 1)) }
    public var celebrityCost: Int { has(.sel) ? 420000 : Self.celebrityCost }
    public var celebrityDays: Int { has(.sel) ? 180 : Self.celebrityDays }
    /// Office bonus on a parked region's income.
    public func officeMultiplier(_ r: RegionID) -> Double {
        (has(.ist) && r == .cap ? 1.25 : 1) * (has(.nyc) && r == .abq ? 1.2 : 1)
    }

    mutating func log(day: Int, income: Int = 0, expense: Int = 0) {
        if history.last?.day != day {
            history.append(Day(day: day, income: 0, expense: 0))
            if history.count > 30 { history.removeFirst() }
        }
        history[history.count - 1].income += income
        history[history.count - 1].expense += expense
    }
}

extension Game {
    /// Demand multiplier from holding campaigns in a region.
    public func holdingBoost(_ r: RegionID) -> Double {
        let h = state.holding, d = state.day
        return (1 + (h.recordBoost ?? 0)) * (h.tvUntil > d ? 1.2 : 1) * ((h.celebrity?.until ?? 0) > d ? 1.1 : 1) * ((h.billboards[r] ?? 0) > d ? 1.1 : 1)
            * ((h.jerseyUntil ?? 0) > d ? Holding.jerseyBoost : 1) * ((h.worldGamesUntil ?? 0) > d ? Holding.worldGamesBoost : 1)
    }

    /// Takes money out of the region you're playing into the holding, converted to euros.
    /// `share` 1 means everything but `Holding.withdrawKeep`.
    @discardableResult
    public mutating func withdraw(share: Double) -> Int {
        let cash = state.cash
        guard cash > Holding.withdrawKeep else { return 0 }
        let amt = share >= 1 ? cash - Holding.withdrawKeep : Int((Double(cash) * share).rounded(.down))
        guard amt > 0 else { return 0 }
        state.cash -= amt
        let eur = jsRound(Double(amt) / state.region.fx)
        state.holding.cash += eur
        state.holding.log(day: state.day, income: eur)
        return amt
    }

    mutating func spendHolding(_ cost: Int) -> Bool {
        guard state.holding.cash >= cost else { return false }
        state.holding.cash -= cost
        state.holding.log(day: state.day, expense: cost)
        return true
    }

    public var canRunTV: Bool { state.holding.tvCooldown <= state.day }

    /// A holding investment gets its due: the guide of the region you're in praises it (celebrities and offices
    /// have their own lines) and the next morning's paper reports it.
    mutating func celebrate(_ d: HoldingDeed) {
        if d != .celebrity && d != .office { state.hezQueue.append(.deed(d)) }
        addPaper(.deed(d))
    }

    @discardableResult
    public mutating func runTVCampaign() -> Bool {
        guard canRunTV, spendHolding(state.holding.tvCost) else { return false }
        state.holding.tvUntil = state.day + Holding.tvDays
        state.holding.tvCooldown = state.day + Holding.tvCooldown
        state.holding.tvCount = (state.holding.tvCount ?? 0) + 1
        state.rep = min(1.4, state.rep + 0.1)
        celebrate(.tv)
        return true
    }

    @discardableResult
    public mutating func signCelebrity() -> Bool {
        guard (state.holding.celebrity?.until ?? 0) <= state.day, spendHolding(state.holding.celebrityCost) else { return false }
        let c = Celebrity(index: rng.int(Holding.celebrityCount), until: state.day + state.holding.celebrityDays)
        state.holding.celebrity = c
        state.rep = min(1.4, state.rep + 0.15)
        state.hezQueue.append(.celebritySigned(c.index))
        celebrate(.celebrity)
        return true
    }

    /// v122.7: sponsor the league champion's jersey.
    @discardableResult
    public mutating func sponsorJersey() -> Bool {
        guard (state.holding.jerseyUntil ?? 0) <= state.day, spendHolding(Holding.jerseyCost) else { return false }
        state.holding.jerseyUntil = state.day + Holding.jerseyDays
        state.rep = min(1.4, state.rep + Holding.jerseyRep)
        celebrate(.jersey)
        return true
    }

    /// v122.7: the balloon show at the World Games' opening ceremony, once.
    @discardableResult
    public mutating func holdWorldGamesShow() -> Bool {
        guard state.worldGamesOpen, state.holding.worldGamesUntil == nil, spendHolding(Holding.worldGamesCost) else { return false }
        state.holding.worldGamesUntil = state.day + Holding.worldGamesDays
        state.rep = min(1.4, state.rep + Holding.worldGamesRep)
        celebrate(.worldGames)
        return true
    }

    @discardableResult
    public mutating func runBillboards() -> Bool {
        let r = state.region
        guard (state.holding.billboards[r] ?? 0) <= state.day, spendHolding(Holding.billboardCost) else { return false }
        state.holding.billboards[r] = state.day + Holding.billboardDays
        celebrate(.billboards)
        return true
    }

    @discardableResult
    public mutating func fundResearch() -> Bool {
        let lv = state.holding.research
        guard lv < Holding.researchLevels.count, spendHolding(Holding.researchLevels[lv].cost) else { return false }
        state.holding.research = lv + 1
        celebrate(.research)
        return true
    }

    @discardableResult
    public mutating func openOffice(_ o: Office) -> Bool {
        guard !state.holding.has(o), spendHolding(o.cost) else { return false }
        state.holding.offices[o] = state.day
        state.hezQueue.append(state.holding.offices.count == Office.allCases.count ? .allOffices : .officeOpened(o))
        celebrate(.office)
        return true
    }

    // MARK: Regions

    /// A region's manager earns this much a day in euros: the median of the last two weeks' profit, or
    /// an estimate from the fleet when there's too little history.
    func makeAutopilot(_ rs: RegionState, region: RegionID) -> Autopilot {
        let h = rs.netHistory.suffix(14).sorted()
        var base: Double
        if h.count >= 3 {
            base = Double(h[h.count / 2])
        } else {
            let cap = rs.balloons.reduce(0) { $0 + $1.size.capacity }
            base = Double(cap * rs.price) * 0.7 - Double(rs.balloons.reduce(0) { $0 + $1.size.fuel + $1.size.upkeep })
                - Double(rs.pilots.reduce(0) { $0 + $1.wage })
        }
        return Autopilot(base: max(0, base) / region.fx * Holding.autopilotEfficiency, since: state.day, lastIssue: state.day)
    }

    func newRegionState(_ r: RegionID) -> RegionState {
        var st = RegionState(rivals: r.startingRivals())
        st.cash = r.startCash
        st.price = r.startPrice
        st.demandBase = r.startDemand
        if r.bristol { st.fogFlown = 0; st.glowCount = 0 }
        st.nextWinter = state.day + 40
        // v125.5: no morning event before the region's welcome cards: the first comes two weeks in
        st.nextEvent = state.day + 14
        st.firstMissionGiven = true
        if r.hasFiesta { st.fiestaNext = state.day + 12 }
        st.balloons.append(Balloon(id: state.nextID, size: .S, name: r.balloonNames[0]))
        st.flagship = state.nextID
        return st
    }

    /// Parks the current region on autopilot and takes over `r`.
    public mutating func switchRegion(_ r: RegionID) {
        guard r != state.region else { return }
        var cur = state.local
        let from = state.region
        var auto = makeAutopilot(cur, region: from)
        // An undecided problem stays with its region: it waits on autopilot and comes back when you do.
        auto.issue = cur.openIssue
        cur.openIssue = nil
        state.parked[from] = ParkedRegion(state: cur, auto: auto)
        var next: RegionState
        if let p = state.parked.removeValue(forKey: r) {
            next = p.state
            next.openIssue = p.auto.issue
            next.issueSeen = nil
        } else {
            next = newRegionState(r)
            state.nextID += 1
        }
        next.weather = nil
        next.demand = nil
        next.plan = nil
        next.candidates = []
        next.rivalPlanDay = 0
        for i in next.rivals.indices { next.rivals[i].flyToday = [] }
        state.local = next
        state.region = r
        startDay()
    }

    public func canEnterRegion(_ r: RegionID) -> Bool { state.holding.cash >= r.entryFee }

    /// Opens a new region with the holding's money. You start over there with a small balloon.
    /// Hezarfen says his piece, then the region's own guide introduces themselves.
    @discardableResult
    public mutating func enterRegion(_ r: RegionID) -> Bool {
        guard !state.owns(r), state.regionOpen(r), !state.needsPack(r), spendHolding(r.entryFee) else { return false }
        state.hezQueue.append(.enteredRegion(r))
        state.hezQueue.append(.guideHello(r))
        // v125: the card to bring balloons and pilots, once, on entering
        if !state.parked.isEmpty || !state.local.balloons.isEmpty { state.transferAsk = r }
        switchRegion(r)
        return true
    }

    /// Parked regions earn for the holding and sometimes need a decision.
    mutating func runAutopilots() {
        for r in RegionID.allCases {
            guard var p = state.parked[r] else { continue }
            var a = p.auto
            a.modifiers.removeAll { $0.until <= state.day }
            let mult = a.modifiers.reduce(1) { $0 * $1.mult } * (a.issue != nil ? 0.5 : 1)
            let inc = a.base * rng.range(0.85, 1.15) * mult
            a.todayRaw = inc
            a.today = jsRound(inc * holdingBoost(r) * state.holding.officeMultiplier(r))
            if a.issue == nil && state.day - a.lastIssue >= 6 && rng.chance(0.07) {
                // A hotel tug-of-war needs a partner hotel there: hotels you own aren't anyone's to take.
                let k = rng.pick(Issue.allCases.filter { $0 != .hotel || !p.state.hotelDeals.isEmpty })
                a.issue = Autopilot.OpenIssue(kind: k, day: state.day)
                a.lastIssue = state.day
                state.hezQueue.append(.regionIssue(r, k))
            }
            p.auto = a
            state.parked[r] = p
        }
    }

    /// Autopilot income reaches the holding minus its own running costs. Returns the net.
    mutating func holdingDay() -> Int {
        var gross = 0.0
        for (r, p) in state.parked { gross += p.auto.todayRaw * holdingBoost(r) * state.holding.officeMultiplier(r) }
        let g = jsRound(gross), cost = jsRound(Double(g) * state.holding.expenseRate)
        state.holding.cash += g - cost
        if g != 0 { state.holding.log(day: state.day, income: g, expense: cost) }
        state.holding.todayGross = g
        state.holding.todayCost = cost
        let extra = recordDay() + adShapeDay()
        return g - cost + extra
    }

    /// What a choice costs the holding up front, for a parked region or the one you're in.
    public func issueCost(in r: RegionID, choice: Issue.Choice) -> Int {
        if r == state.region {
            guard let open = state.local.openIssue else { return 0 }
            // On the spot, keeping the hotel costs two months of that hotel's own fee (in the holding's euros), not the
            // region's five days of autopilot earnings, which made paying pointless next to a three-day re-signing.
            if open.kind == .hotel && choice == .a, let h = state.hotelDeals.last {
                return jsRound(Double(h.dailyFee * Rules.hotelKeepDays) / r.fx / 100) * 100
            }
            return open.kind.cost(choice, base: makeAutopilot(state.local, region: r).base)
        }
        guard let p = state.parked[r], let open = p.auto.issue else { return 0 }
        return open.kind.cost(choice, base: p.auto.base)
    }

    /// The problem waiting in the region you're in, if any.
    public var liveIssue: Issue? { state.local.openIssue?.kind }

    /// True once a day while a problem waits in the region you're in: its card opens by itself.
    public mutating func liveIssueCardDue() -> Bool {
        guard state.local.openIssue != nil, state.local.issueSeen != state.day else { return false }
        state.local.issueSeen = state.day
        return true
    }

    /// Answer a parked region's problem. Paying comes out of the holding. In the region you're in, the choice
    /// plays out on the spot: wages, a three-day strike, ticket price, popularity, a hotel or the envelopes.
    @discardableResult
    public mutating func resolveIssue(in r: RegionID, choice: Issue.Choice) -> Bool {
        if r == state.region { return resolveLiveIssue(choice) }
        guard var p = state.parked[r], let open = p.auto.issue else { return false }
        let cost = open.kind.cost(choice, base: p.auto.base)
        if cost > 0 && !spendHolding(cost) { return false }
        var goThere = false
        let d = state.day
        switch (open.kind, choice) {
        case (.raise, .a): p.auto.base *= 0.94
        case (.raise, .b): p.auto.modifiers.append(.init(mult: 0, until: d + 3))
        case (.war, .a): p.auto.base *= 0.9
        case (.war, .b): if rng.chance(0.5) { p.auto.modifiers.append(.init(mult: 0.75, until: d + 10)) }
        case (.accident, .a): p.state.rep = max(0.4, p.state.rep - 0.05); goThere = true
        case (.accident, .b): p.auto.modifiers.append(.init(mult: 0.85, until: d + 7))
        case (.hotel, .a): break
        case (.hotel, .b): p.auto.base *= 0.95
        case (.envelope, .a): break
        case (.envelope, .b): p.auto.modifiers.append(.init(mult: 0.88, until: d + 10))
        }
        p.auto.issue = nil
        state.parked[r] = p
        if goThere { switchRegion(r) }
        return true
    }

    mutating func resolveLiveIssue(_ choice: Issue.Choice) -> Bool {
        guard let open = state.local.openIssue else { return false }
        let cost = issueCost(in: state.region, choice: choice)
        if cost > 0 && !spendHolding(cost) { return false }
        let d = state.day
        switch (open.kind, choice) {
        case (.raise, .a):
            for i in state.pilots.indices { state.pilots[i].customWage = raisedWage(state.pilots[i]) }
        case (.raise, .b):
            state.strikeUntil = d + 2
            state.selfFly = true
            assignPilots()
        case (.war, .a):
            if let low = state.rivals.filter(\.alive).map(\.price).min() { state.price = min(state.price, low) }
        case (.war, .b):
            if rng.chance(0.5) { state.rep = max(0.4, state.rep - 0.08) }
        case (.accident, .a): state.rep = max(0.4, state.rep - 0.05)
        case (.accident, .b): state.rep = max(0.4, state.rep - 0.1)
        case (.hotel, .a): break
        case (.hotel, .b):
            // The hotel goes to the most popular rival for a month, so letting it go and signing it again the same
            // day (three days' fee instead of the payment) is no way out.
            if let h = state.hotelDeals.popLast() {
                let r = state.rivals.filter(\.alive).max { $0.rep < $1.rep }
                state.hotelLocks[h] = HotelLock(rival: r?.name ?? "", until: d + Rules.hotelLostDays)
            }
        case (.envelope, .a):
            for i in state.balloons.indices where state.condition(state.balloons[i]) < 0.3 { state.balloons[i].flights = 0 }
        case (.envelope, .b): break
        }
        state.local.openIssue = nil
        return true
    }
}

extension GameState {
    /// v123.5: Baron of Bristol, the fourth region. 
    public var bristolBaron: Bool { barons[.bri] != nil }
    /// v123.5: the World Games show is the holding's finale: it opens once you're Baron of Bristol.
    public var worldGamesOpen: Bool { bristolBaron }
}
