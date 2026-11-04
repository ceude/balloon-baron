import Foundation

/// City offices of the holding. Perks stack; any four cut holding expenses, all six cut them further.
public enum Office: String, Codable, CaseIterable, CodingKeyRepresentable, Sendable {
    case ist, nyc, sel, tyo
    /// v137: Dubai and Paris. v141 (developer): Dubai lifts the Maasai Mara's autopilot +20% (records 25% cheaper as
    /// before; its old Luxor +20% moved to Tokyo); Paris became London (Bristol +20%, the documentary 20% cheaper), its
    /// saved key stays "par" so an office bought as Paris is the London office.
    case dxb, lon = "par"

    /// v137 (developer): all six cost about the same, around €700,000 (they were €350,000–450,000, Dubai and Paris
    /// €1.5M and €1.8M).
    public var cost: Int { [650_000, 750_000, 700_000, 700_000, 700_000, 750_000][index] }
    /// v140 (developer): each office's rent and staff, euros a day, paid by the holding every evening.
    public var rent: Int { [1000, 2000, 1500, 1500, 1500, 2000][index] }
    private var index: Int { Self.allCases.firstIndex(of: self)! }

    /// v141 (developer): the region you must have entered (own) before this office can open: New York with Albuquerque,
    /// Tokyo with Luxor, London with Bristol, Dubai with the Maasai Mara. İstanbul and Seoul need nothing. An office
    /// already open stays open.
    public var needs: RegionID? {
        switch self {
        case .ist, .sel: nil
        case .nyc: .abq
        case .tyo: .lux
        case .lon: .bri
        case .dxb: .mara
        }
    }

    /// v141.1 (developer): the order the offices are listed in everywhere: İstanbul, Seoul, New York, London, Tokyo,
    /// Dubai (it replaces v138's cheapest-first). `allCases` itself stays as it is (saves and goals).
    public static let listed: [Office] = [.ist, .sel, .nyc, .lon, .tyo, .dxb]
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
    /// v137 (developer): any four offices bring the holding's running costs down to 20%, all six to 15%.
    public static let fourOfficesExpenseRate = 0.2, allOfficesExpenseRate = 0.15, fewOffices = 4
    public static let entryFee = 100000
    /// Share of a parked region's typical profit its manager delivers.
    public static let autopilotEfficiency = 0.85
    /// v136 (TestFlight): the TV campaign runs in one region's national channels, bought for each region on its own (it
    /// used to be one €250,000 campaign for every region). €60,000 a region: four regions cost about what the old one
    /// did, and the simulator's regions earn €45,000–90,000 back each over its 14 days. Popularity +0.1 in that region.
    /// v140 (developer, `tools/sim-holding.js`): €120,000 for 21 days, +15%, a new one 45 days after the last (it was
    /// €60,000, 14 days, +20%, 30 days).
    public static let tvCost = 120_000, tvDays = 21, tvCooldown = 45, tvRep = 0.1, tvBoost = 1.15
    /// v136: the popularity each worldwide deal adds in every region you own (`Game.repEverywhere`).
    /// v140 (developer): €1.8M for 180 days (was €600,000 for 90). The first deal, a holding goal, stays €600,000 (a
    /// rising star signs for less); Seoul takes 25% off either (it made them twice as long and 30% cheaper).
    public static let celebrityCost = 1_800_000, celebrityFirstCost = 600_000, celebrityDays = 180, celebrityCount = 6
    public static let celebrityRep = 0.15, celebrityBoost = 1.1, seoulDiscount = 0.75
    /// v140: €80,000 for 30 days, +8% (were €120,000, 20 days, +10%).
    public static let billboardCost = 80000, billboardDays = 30, billboardBoost = 1.08
    /// v122.7 (`JERSEY`, `WGAMES`): the league champion's jersey (no team named, the game is played worldwide), and the
    /// balloon show at the World Games' opening ceremony. v140 (developer): the jersey €10M for a season of 360 days
    /// (was €3M, 180); the World Games come round every 360 days after a show, each show 1.5 times the last (€10M,
    /// €15M, €22.5M...).
    public static let jerseyCost = 10_000_000, jerseyDays = 360, jerseyBoost = 1.15, jerseyRep = 0.1
    public static let worldGamesCost = 10_000_000, worldGamesDays = 60, worldGamesBoost = 1.3, worldGamesRep = 0.2
    public static let worldGamesAgain = 360, worldGamesStep = 1.5
    /// v140 (developer): the International Balloon Festival the holding hosts in a region it owns. One at a time, a new
    /// one 90 days after the last; €1.5M, each €500,000 more than the one before, at most €5M. Ten days of +40% tourists
    /// there and +0.15 popularity there; every festival held in a region adds +3% tourists there for good (its festival
    /// fame), up to +15%.
    public static let festivalBase = 1_500_000, festivalStep = 500_000, festivalMax = 5_000_000
    public static let festivalEvery = 90, festivalDays = 10, festivalBoost = 1.4, festivalRep = 0.15
    public static let festivalFame = 0.03, festivalFameMax = 0.15
    /// v140 (developer): the Hot Air Foundation. Projects without end, €1M and each €500,000 more than the last; each is
    /// a named project in a region you own and lifts popularity in every region you own.
    public static let foundationBase = 1_000_000, foundationStep = 500_000, foundationRep = 0.05
    /// v140: Tokyo's Asian tour operators bring +5% tourists to every region; Paris lifts Bristol by 20% also while you
    /// play there (it lifted only its autopilot income).
    public static let tokyoBoost = 1.05, londonBoost = 1.2
    /// Levels 1 and 2 are the envelope research. v137: level 3 is a weather radar network, level 4 a composite basket and
    /// an efficient burner (they keep the envelope's 200 flights). The holding goal wants all four.
    public static let researchLevels = [ResearchLevel(cost: 400000, life: 160), ResearchLevel(cost: 900000, life: 200),
                                        ResearchLevel(cost: 2_000_000, life: 200), ResearchLevel(cost: 4_000_000, life: 200)]
    public static let envelopeResearch = 2, radarLevel = 3, compositeLevel = 4
    /// v137: the radar cuts accident risk (and so the premiums) by 15%; the composite basket fuel by 25% and upkeep by
    /// 15%. Parked regions earn what that saves a late-game region: +5% and +2% (`tools/sim-campaign.js`: premiums are
    /// about 36% of its net, fuel and upkeep 8%).
    /// v140 (developer): level 4 lifts parked regions by 5% too (it was 2%), so the €4M level is felt.
    public static let radarAccident = 0.85, radarAutopilot = 1.05
    public static let compositeFuel = 0.75, compositeUpkeep = 0.85, compositeAutopilot = 1.05
    /// v137: the streaming documentary series: demand in every region for 120 days, popularity in every region you own,
    /// and a new season 60 days after one ends.
    /// v140: €3M (was €2.5M); Paris still takes 20% off.
    public static let documentaryCost = 3_000_000, documentaryDays = 120, documentaryGap = 60
    public static let documentaryBoost = 1.15, documentaryRep = 0.1
    /// What you leave in a region's cash box when you take "all".
    public static let withdrawKeep = 10000
    /// v141.1: what a transfer leaves in a region's box: `withdrawKeep`, in the Maasai Mara `Mara.withdrawKeep`.
    public static func withdrawKeep(_ r: RegionID) -> Int { r == .mara ? Mara.withdrawKeep : withdrawKeep }

    public var cash = 0
    /// Last 30 days of income and expenses.
    public var history: [Day] = []
    /// Yesterday's autopilot income and expenses.
    public var todayGross = 0, todayCost = 0
    /// Before v136: the one national TV campaign (every region) ran until `tvUntil`, the next could start on `tvCooldown`.
    /// New campaigns never set these; an old save's run and wait still count for every region (`tvUntil(_:)`).
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
    /// v131: parked regions whose autopilot profit stays in their own cash box instead of reaching the holding (the
    /// player moves it by hand). nil or absent: the region sends (the default).
    public var keepIn: [RegionID]?
    /// v132 (TestFlight): the day the holding's cash first reached `millionGoal`. The goal stays ticked from then on,
    /// whatever the cash does later (it used to untick when the money was spent).
    public var millionOn: Int?
    public static let millionGoal = 1_000_000
    /// v133: the day the holding rescued each region from the bank (once per region), and the day each region's company
    /// was closed (cleared when it is entered again). nil in older saves.
    public var rescued: [RegionID: Int]?
    public var closed: [RegionID: Int]?
    /// v136: each region's own TV campaign (nil in older saves).
    public var tv: [RegionID: TVRun]?
    /// v137: the documentary series (nil until the first season).
    public var documentary: Documentary?
    /// v137: true once the records use the new ladder (`world` was the €900,000 attempt before; see `RecordAttempt`).
    /// A new holding starts on it; an older save has no key and decodes nil.
    public var recordsV2: Bool? = true
    /// v140: how many World Games shows were held and the day of the last (nil in older saves: one show, held
    /// `worldGamesDays` before `worldGamesUntil`).
    public var worldGamesCount: Int?
    public var worldGamesOn: Int?
    /// v140: the International Balloon Festival (nil until the first) and the festivals held in each region.
    public var festival: HostedFestival?
    public var festivalsIn: [RegionID: Int]?
    /// v140: the Hot Air Foundation's projects in each region (nil until the first) and the last one funded.
    public var foundation: [RegionID: Int]?
    public var lastProject: FundedProject?
    /// v140: yesterday's office rent (nil in older saves).
    public var todayRent: Int?

    public struct HostedFestival: Codable, Equatable, Sendable {
        public var region: RegionID
        /// The festival runs until `until`; the next can be held from `next`. `count`: festivals held so far.
        public var until: Int
        public var next: Int
        public var count: Int
    }

    public struct FundedProject: Codable, Equatable, Sendable {
        public var region: RegionID
        /// Index into that region's list (`fdn.<region>.<index % perRegion>`), and the day it was funded.
        public var index: Int
        public var day: Int
    }

    public struct Documentary: Codable, Equatable, Sendable {
        /// The season on air runs until `until`; the next can be made from `next`.
        public var until: Int
        public var next: Int
        public var season: Int
    }

    public struct TVRun: Codable, Equatable, Sendable {
        public var until: Int
        /// The day the next campaign can start in that region.
        public var cooldown: Int
    }

    /// v136: the last day of a region's TV campaign. An old save's national campaign counts in every region, as it did.
    public func tvUntil(_ r: RegionID) -> Int { max(tv?[r]?.until ?? 0, tvUntil) }
    /// v136: the day the next TV campaign can start in a region.
    public func tvReady(_ r: RegionID) -> Int { max(tv?[r]?.cooldown ?? 0, tvCooldown) }

    /// v131: a parked region's autopilot profit goes to the holding each day.
    public func sends(_ r: RegionID) -> Bool { !(keepIn ?? []).contains(r) }

    public func has(_ o: Office) -> Bool { offices[o] != nil }
    public var expenseRate: Double {
        offices.count >= Office.allCases.count ? Self.allOfficesExpenseRate : offices.count >= Self.fewOffices ? Self.fourOfficesExpenseRate : Self.expenseRate
    }
    /// v137: what the R&D levels bought so far do.
    public var accidentFactor: Double { research >= Self.radarLevel ? Self.radarAccident : 1 }
    public var fuelFactor: Double { research >= Self.compositeLevel ? Self.compositeFuel : 1 }
    public var upkeepFactor: Double { research >= Self.compositeLevel ? Self.compositeUpkeep : 1 }
    public var researchAutopilot: Double {
        (research >= Self.radarLevel ? Self.radarAutopilot : 1) * (research >= Self.compositeLevel ? Self.compositeAutopilot : 1)
    }
    public var documentaryCost: Int { jsRound(Double(Self.documentaryCost) * (has(.lon) ? 0.8 : 1)) }
    /// v140: the offices' rent and staff, euros a day.
    public var officeRent: Int { offices.keys.reduce(0) { $0 + $1.rent } }
    /// v140: World Games shows held, the day of the last, the next show's price and the first day it can be held.
    public var worldGamesHeld: Int { worldGamesUntil == nil ? 0 : worldGamesCount ?? 1 }
    public var worldGamesLast: Int? { worldGamesUntil.map { worldGamesOn ?? $0 - Self.worldGamesDays } }
    public var worldGamesPrice: Int { jsRound(Double(Self.worldGamesCost) * pow(Self.worldGamesStep, Double(worldGamesHeld))) }
    public var worldGamesNext: Int { worldGamesLast.map { $0 + Self.worldGamesAgain } ?? 0 }
    /// v140: the next festival's price, whether one runs in a region, a region's lasting festival fame.
    public var festivalCost: Int { min(Self.festivalMax, Self.festivalBase + Self.festivalStep * (festival?.count ?? 0)) }
    public func festivalOn(_ r: RegionID, day: Int) -> Bool { festival.map { $0.region == r && $0.until > day } ?? false }
    public func festivalReady(day: Int) -> Bool { (festival?.next ?? 0) <= day }
    public func festivalFame(_ r: RegionID) -> Double { min(Self.festivalFameMax, Self.festivalFame * Double(festivalsIn?[r] ?? 0)) }
    /// v140: the foundation's projects in all and in one region, and the next project's price.
    public var projects: Int { foundation?.values.reduce(0, +) ?? 0 }
    public func projects(in r: RegionID) -> Int { foundation?[r] ?? 0 }
    public var projectCost: Int { Self.foundationBase + Self.foundationStep * projects }
    public func documentaryOn(_ day: Int) -> Bool { (documentary?.until ?? 0) > day }
    /// v137: a record attempt's price (Dubai's office takes a quarter off).
    public func recordCost(_ k: RecordAttempt) -> Int { jsRound(Double(k.cost) * (has(.dxb) ? 0.75 : 1)) }
    public var tvCost: Int { jsRound(Double(Self.tvCost) * (has(.nyc) ? 0.75 : 1)) }
    public var celebrityCost: Int { jsRound(Double(celebrity == nil ? Self.celebrityFirstCost : Self.celebrityCost) * (has(.sel) ? Self.seoulDiscount : 1)) }
    public var celebrityDays: Int { Self.celebrityDays }
    /// Office bonus on a parked region's income; v137: with the R&D levels' savings.
    public func officeMultiplier(_ r: RegionID) -> Double {
        (has(.ist) && r == .cap ? 1.25 : 1) * (has(.nyc) && r == .abq ? 1.2 : 1)
            * (has(.tyo) && r == .lux ? 1.2 : 1) * (has(.dxb) && r == .mara ? 1.2 : 1) * (has(.lon) && r == .bri ? Self.londonBoost : 1)
            * (has(.tyo) ? Self.tokyoBoost : 1) * researchAutopilot
    }
    /// v140: the offices' pull on tourists in the region you play: Tokyo everywhere, London (was Paris) in Bristol. Parked
    /// regions get theirs in `officeMultiplier`.
    public func officeHere(_ r: RegionID) -> Double { (has(.tyo) ? Self.tokyoBoost : 1) * (has(.lon) && r == .bri ? Self.londonBoost : 1) }

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
        return (1 + (h.recordBoost ?? 0)) * (h.tvUntil(r) > d ? Holding.tvBoost : 1) * ((h.celebrity?.until ?? 0) > d ? Holding.celebrityBoost : 1)
            * ((h.billboards[r] ?? 0) > d ? Holding.billboardBoost : 1)
            * ((h.jerseyUntil ?? 0) > d ? Holding.jerseyBoost : 1) * ((h.worldGamesUntil ?? 0) > d ? Holding.worldGamesBoost : 1)
            * (h.documentaryOn(d) ? Holding.documentaryBoost : 1) * festivalBoost(r)
    }

    /// v140: the hosted festival's ten days in a region and that region's lasting festival fame.
    public func festivalBoost(_ r: RegionID) -> Double {
        (state.holding.festivalOn(r, day: state.day) ? Holding.festivalBoost : 1) * (1 + state.holding.festivalFame(r))
    }

    /// Takes money out of the region you're playing into the holding, converted to euros.
    /// `share` 1 means everything but `Holding.withdrawKeep`.
    @discardableResult
    public mutating func withdraw(share: Double) -> Int {
        let cash = state.cash, keep = Holding.withdrawKeep(state.region)
        guard cash > keep else { return 0 }
        let amt = share >= 1 ? cash - keep : Int((Double(cash) * share).rounded(.down))
        guard amt > 0 else { return 0 }
        state.cash -= amt
        let eur = jsRound(Double(amt) / state.region.fx)
        state.holding.cash += eur
        state.holding.log(day: state.day, income: eur)
        holdingGoalsNow()
        return amt
    }

    /// v131: turns a region's daily delivery to the holding on or off. Off, its autopilot profit stays in its cash box.
    public mutating func setSendsToHolding(_ r: RegionID, _ on: Bool) {
        var k = (state.holding.keepIn ?? []).filter { $0 != r }
        if !on { k.append(r) }
        state.holding.keepIn = k.isEmpty ? nil : k.sorted { $0.rawValue < $1.rawValue }
    }

    /// The cash box of a region you own: the one you're in, or a parked one.
    public func regionCash(_ r: RegionID) -> Int? { r == state.region ? state.cash : state.parked[r]?.state.cash }

    /// v131: moves money from a parked region's cash box to the holding, like `withdraw` does for the region you're in.
    @discardableResult
    public mutating func withdraw(from r: RegionID, share: Double) -> Int {
        if r == state.region { return withdraw(share: share) }
        guard var p = state.parked[r] else { return 0 }
        let cash = p.state.cash, keep = Holding.withdrawKeep(r)
        guard cash > keep else { return 0 }
        let amt = share >= 1 ? cash - keep : Int((Double(cash) * share).rounded(.down))
        guard amt > 0 else { return 0 }
        p.state.cash -= amt
        state.parked[r] = p
        let eur = jsRound(Double(amt) / r.fx)
        state.holding.cash += eur
        state.holding.log(day: state.day, income: eur)
        holdingGoalsNow()
        return amt
    }

    mutating func spendHolding(_ cost: Int) -> Bool {
        guard state.holding.cash >= cost else { return false }
        state.holding.cash -= cost
        state.holding.log(day: state.day, expense: cost)
        return true
    }

    /// v136: the regions you own, in map order: the one you're in and the parked ones (a closed region isn't parked).
    public var ownedRegions: [RegionID] { RegionID.allCases.filter { state.owns($0) } }

    public var canRunTV: Bool { canRunTV(in: state.region) }
    /// v136: a region's own TV campaign can start (owned, and its 30-day wait is over).
    public func canRunTV(in r: RegionID) -> Bool { state.owns(r) && state.holding.tvReady(r) <= state.day }
    public func billboardsUp(in r: RegionID) -> Bool { (state.holding.billboards[r] ?? 0) > state.day }

    /// v136: popularity in one region you own, the one you're in or a parked one, up to its maximum.
    mutating func repIn(_ r: RegionID, _ d: Double) {
        let top = Rules.repRange.upperBound
        if r == state.region { state.rep = min(top, state.rep + d) } else if var p = state.parked[r] {
            p.state.rep = min(top, p.state.rep + d)
            state.parked[r] = p
        }
    }

    /// A holding investment gets its due: the guide of the region you're in praises it (celebrities and offices
    /// have their own lines) and the next morning's paper reports it.
    mutating func celebrate(_ d: HoldingDeed) {
        if d != .celebrity && d != .office { state.hezQueue.append(.deed(d)) }
        addPaper(.deed(d))
    }

    /// v136 (TestFlight): a national or worldwide campaign lifts popularity in every region you own on the day you buy it:
    /// the one you're in and each parked one, each up to its own maximum. It used to lift only the region you happened
    /// to be in. A region entered later starts from its own popularity (the bump happened on the day of the campaign).
    /// Inside `finishDay` (a world record) the region you're in logs it under `why` for the report.
    mutating func repEverywhere(_ d: Double, _ why: RepReason? = nil) {
        let top = Rules.repRange.upperBound, r0 = state.rep
        state.rep = min(top, state.rep + d)
        if let why { repMark(why, since: r0) }
        for r in Array(state.parked.keys) {
            guard var p = state.parked[r] else { continue }
            p.state.rep = min(top, p.state.rep + d)
            state.parked[r] = p
        }
    }

    /// v136: a TV campaign in one region's channels (the one you're in by default), bought from any region.
    @discardableResult
    public mutating func runTVCampaign(in region: RegionID? = nil) -> Bool {
        let r = region ?? state.region
        guard canRunTV(in: r), spendHolding(state.holding.tvCost) else { return false }
        var tv = state.holding.tv ?? [:]
        tv[r] = Holding.TVRun(until: state.day + Holding.tvDays, cooldown: state.day + Holding.tvCooldown)
        state.holding.tv = tv
        state.holding.tvCount = (state.holding.tvCount ?? 0) + 1
        repIn(r, Holding.tvRep)
        celebrate(.tv)
        return true
    }

    @discardableResult
    public mutating func signCelebrity() -> Bool {
        guard (state.holding.celebrity?.until ?? 0) <= state.day, spendHolding(state.holding.celebrityCost) else { return false }
        let c = Celebrity(index: rng.int(Holding.celebrityCount), until: state.day + state.holding.celebrityDays)
        state.holding.celebrity = c
        repEverywhere(Holding.celebrityRep)
        state.hezQueue.append(.celebritySigned(c.index))
        celebrate(.celebrity)
        return true
    }

    /// v122.7: sponsor the league champion's jersey.
    @discardableResult
    public mutating func sponsorJersey() -> Bool {
        guard (state.holding.jerseyUntil ?? 0) <= state.day, spendHolding(Holding.jerseyCost) else { return false }
        state.holding.jerseyUntil = state.day + Holding.jerseyDays
        repEverywhere(Holding.jerseyRep)
        celebrate(.jersey)
        return true
    }

    /// v140: a World Games show can be held: open (the Bristol baron), none in effect, 360 days since the last.
    public var canHoldWorldGames: Bool {
        let h = state.holding
        return state.worldGamesOpen && (h.worldGamesUntil ?? 0) <= state.day && h.worldGamesNext <= state.day
    }

    /// v122.7: the balloon show at the World Games' opening ceremony. v140: again every 360 days, each 1.5 times the last.
    @discardableResult
    public mutating func holdWorldGamesShow() -> Bool {
        let n = state.holding.worldGamesHeld
        guard canHoldWorldGames, spendHolding(state.holding.worldGamesPrice) else { return false }
        state.holding.worldGamesUntil = state.day + Holding.worldGamesDays
        state.holding.worldGamesOn = state.day
        state.holding.worldGamesCount = n + 1
        repEverywhere(Holding.worldGamesRep)
        celebrate(.worldGames)
        return true
    }

    /// v140: the holding's International Balloon Festival can be held in a region you own (none running, 90 days since
    /// the last).
    public func canHostFestival(in r: RegionID) -> Bool { state.owns(r) && state.holding.festivalReady(day: state.day) }

    /// v140: the International Balloon Festival in a region you own: ten days of tourists, popularity there, and the
    /// region's festival fame. The guide says so and the paper reports it.
    @discardableResult
    public mutating func hostFestival(in r: RegionID) -> Bool {
        guard canHostFestival(in: r), spendHolding(state.holding.festivalCost) else { return false }
        let d = state.day
        state.holding.festival = Holding.HostedFestival(region: r, until: d + Holding.festivalDays, next: d + Holding.festivalEvery,
                                                        count: (state.holding.festival?.count ?? 0) + 1)
        var n = state.holding.festivalsIn ?? [:]
        n[r, default: 0] += 1
        state.holding.festivalsIn = n
        repIn(r, Holding.festivalRep)
        state.hezQueue.append(.festivalHosted(r))
        addPaper(.festivalHosted(r))
        return true
    }

    /// v140: the Hot Air Foundation funds its next project in a region you own: popularity in every region you own, a
    /// monument in that region's town, the guide's word and a story in the paper.
    @discardableResult
    public mutating func fundProject(in r: RegionID) -> Bool {
        guard state.owns(r), spendHolding(state.holding.projectCost) else { return false }
        let i = state.holding.projects(in: r)
        var f = state.holding.foundation ?? [:]
        f[r] = i + 1
        state.holding.foundation = f
        state.holding.lastProject = Holding.FundedProject(region: r, index: i, day: state.day)
        repEverywhere(Holding.foundationRep)
        state.hezQueue.append(.foundationProject(r, i))
        addPaper(.foundationProject(r, i, count: state.holding.projects))
        return true
    }

    /// Billboards in one region (the one you're in by default); v136: any region you own, from any region.
    @discardableResult
    public mutating func runBillboards(in region: RegionID? = nil) -> Bool {
        let r = region ?? state.region
        guard state.owns(r), !billboardsUp(in: r), spendHolding(Holding.billboardCost) else { return false }
        state.holding.billboards[r] = state.day + Holding.billboardDays
        celebrate(.billboards)
        return true
    }

    @discardableResult
    public mutating func fundResearch() -> Bool {
        let lv = state.holding.research
        guard lv < Holding.researchLevels.count, spendHolding(Holding.researchLevels[lv].cost) else { return false }
        state.holding.research = lv + 1
        celebrate(lv + 1 == Holding.radarLevel ? .radar : lv + 1 == Holding.compositeLevel ? .composite : .research)
        return true
    }

    @discardableResult
    public mutating func openOffice(_ o: Office) -> Bool {
        guard !state.holding.has(o), canOpenOffice(o), spendHolding(o.cost) else { return false }
        state.holding.offices[o] = state.day
        let n = state.holding.offices.count
        state.hezQueue.append(n == Office.allCases.count ? .sixOffices : n == Holding.fewOffices ? .allOffices : .officeOpened(o))
        celebrate(.office)
        return true
    }

    /// v141: the office's region has been entered (or it needs none, or it is already open).
    public func canOpenOffice(_ o: Office) -> Bool { state.holding.has(o) || o.needs.map { state.owns($0) } ?? true }

    /// v137: a documentary season can be made (none on air, and the gap after the last one is over).
    public var canMakeDocumentary: Bool { (state.holding.documentary?.next ?? 0) <= state.day }

    /// v137: the streaming documentary series about the company: a new season.
    @discardableResult
    public mutating func makeDocumentary() -> Bool {
        guard canMakeDocumentary, spendHolding(state.holding.documentaryCost) else { return false }
        let d = state.day
        state.holding.documentary = Holding.Documentary(until: d + Holding.documentaryDays, next: d + Holding.documentaryDays + Holding.documentaryGap,
                                                        season: (state.holding.documentary?.season ?? 0) + 1)
        repEverywhere(Holding.documentaryRep)
        celebrate(.documentary)
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
        st.nextWinter = state.day + (r.rainy ? Mara.firstRains : 40)
        if r.rainy { st.rainsDone = 0; st.rainsCount = 0 }
        // v125.5: no morning event before the region's welcome cards: the first comes two weeks in
        st.nextEvent = state.day + 14
        st.firstMissionGiven = true
        if r.hasFiesta { st.fiestaNext = state.day + (r == .mara ? Mara.firstMigration : 12) }
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
        // v132 (TestFlight): a Balloon Show or Night Glow booked for tonight can't happen with you gone. It's called
        // off, its fee goes back to that region's cash box and the guide says so (it used to vanish without a word).
        if cur.showTonight == state.day, let ids = cur.showIDs {
            let refund = ids.filter { id in cur.balloons.contains { $0.id == id } }.count * Rules.showPerBalloon
            cur.cash += refund
            cur.showTonight = nil
            cur.showIDs = nil
            cur.showNext = nil
            cur.showCount = max(0, (cur.showCount ?? 1) - 1)
            state.hezQueue.append(.nightCalledOff(from, show: true, refund: refund))
        }
        if cur.glowTonight == state.day {
            cur.cash += Glow.cost
            cur.glowTonight = nil
            cur.glowFest = nil
            cur.glowN = nil
            state.hezQueue.append(.nightCalledOff(from, show: false, refund: Glow.cost))
        }
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
        // v133: a region whose company closed, entered again (Cappadocia only ever this way)
        state.holding.closed?[r] = nil
        if state.holding.closed?.isEmpty == true { state.holding.closed = nil }
        if r == .cap {
            state.hezQueue.append(.capReentered)
        } else {
            state.hezQueue.append(.enteredRegion(r))
            state.hezQueue.append(.guideHello(r))
        }
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
    /// v131: a region set to keep its money gets the same net (after the holding's running costs, so keeping and moving
    /// by hand later is no way around them) in its own cash box and currency.
    mutating func holdingDay() -> Int {
        var gross = 0.0
        for (r, p) in state.parked {
            let day = p.auto.todayRaw * holdingBoost(r) * state.holding.officeMultiplier(r)
            if state.holding.sends(r) {
                gross += day
            } else if var q = state.parked[r] {
                let kept = jsRound(Double(jsRound(day)) * (1 - state.holding.expenseRate) * r.fx)
                q.state.cash += kept
                q.auto.kept = kept
                state.parked[r] = q
            }
        }
        let g = jsRound(gross), cost = jsRound(Double(g) * state.holding.expenseRate)
        // v140: the offices' rent and staff, every evening (never more than the holding has)
        let rent = min(state.holding.officeRent, max(0, state.holding.cash + g - cost))
        state.holding.cash += g - cost - rent
        if g != 0 || rent != 0 { state.holding.log(day: state.day, income: g, expense: cost + rent) }
        state.holding.todayGross = g
        state.holding.todayCost = cost
        state.holding.todayRent = rent == 0 && state.holding.todayRent == nil ? nil : rent
        let extra = recordDay() + adShapeDay()
        markMillion()
        return g - cost - rent + extra
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
    /// v140: the holding's International Balloon Festival is on in the region you're in (the sky fills like a Fiesta's,
    /// bunting in the town, a glow on its nights).
    public var hostedFestivalHere: Bool { holding.festivalOn(region, day: day) }
    /// v123.5: Baron of Bristol, the fourth region. 
    public var bristolBaron: Bool { barons[.bri] != nil }
    /// v123.5: the World Games show is the holding's finale: it opens once you're Baron of Bristol.
    public var worldGamesOpen: Bool { bristolBaron }
}
