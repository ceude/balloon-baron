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
        return (h.tvUntil > d ? 1.2 : 1) * ((h.celebrity?.until ?? 0) > d ? 1.1 : 1) * ((h.billboards[r] ?? 0) > d ? 1.1 : 1)
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

    @discardableResult
    public mutating func runTVCampaign() -> Bool {
        guard canRunTV, spendHolding(state.holding.tvCost) else { return false }
        state.holding.tvUntil = state.day + Holding.tvDays
        state.holding.tvCooldown = state.day + Holding.tvCooldown
        state.rep = min(1.4, state.rep + 0.1)
        return true
    }

    @discardableResult
    public mutating func signCelebrity() -> Bool {
        guard (state.holding.celebrity?.until ?? 0) <= state.day, spendHolding(state.holding.celebrityCost) else { return false }
        let c = Celebrity(index: rng.int(Holding.celebrityCount), until: state.day + state.holding.celebrityDays)
        state.holding.celebrity = c
        state.rep = min(1.4, state.rep + 0.15)
        state.hezQueue.append(.celebritySigned(c.index))
        return true
    }

    @discardableResult
    public mutating func runBillboards() -> Bool {
        let r = state.region
        guard (state.holding.billboards[r] ?? 0) <= state.day, spendHolding(Holding.billboardCost) else { return false }
        state.holding.billboards[r] = state.day + Holding.billboardDays
        return true
    }

    @discardableResult
    public mutating func fundResearch() -> Bool {
        let lv = state.holding.research
        guard lv < Holding.researchLevels.count, spendHolding(Holding.researchLevels[lv].cost) else { return false }
        state.holding.research = lv + 1
        return true
    }

    @discardableResult
    public mutating func openOffice(_ o: Office) -> Bool {
        guard !state.holding.has(o), spendHolding(o.cost) else { return false }
        state.holding.offices[o] = state.day
        state.hezQueue.append(state.holding.offices.count == Office.allCases.count ? .allOffices : .officeOpened(o))
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
        st.nextWinter = state.day + 40
        st.firstMissionGiven = true
        if r.hasFiesta { st.fiestaNext = state.day + 12 }
        st.balloons.append(Balloon(id: state.nextID, size: .S, name: r.balloonNames[0]))
        st.flagship = state.nextID
        return st
    }

    /// Parks the current region on autopilot and takes over `r`.
    public mutating func switchRegion(_ r: RegionID) {
        guard r != state.region else { return }
        let cur = state.local, from = state.region
        state.parked[from] = ParkedRegion(state: cur, auto: makeAutopilot(cur, region: from))
        var next: RegionState
        if let p = state.parked.removeValue(forKey: r) {
            next = p.state
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

    public var canEnterRegion: Bool { state.holding.cash >= Holding.entryFee }

    /// Opens a new region with the holding's money. You start over there with a small balloon.
    @discardableResult
    public mutating func enterRegion(_ r: RegionID) -> Bool {
        guard !state.owns(r), state.isBaron(.cap), spendHolding(Holding.entryFee) else { return false }
        state.hezQueue.append(.enteredRegion(r))
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
                let k = rng.pick(Issue.allCases)
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
        return g - cost
    }

    /// Answer a parked region's problem. Paying comes out of the holding.
    @discardableResult
    public mutating func resolveIssue(in r: RegionID, choice: Issue.Choice) -> Bool {
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
}
