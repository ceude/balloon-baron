import Foundation

/// The whole simulation. A value type: the app keeps one in an observable store and saves `state`.
public struct Game: Sendable {
    public var state: GameState
    var rng: SplitMix64

    public init(company: String, colors: [String], seed: UInt64 = .random(in: 0...UInt64.max)) {
        state = GameState(company: company, colors: colors)
        rng = SplitMix64(seed: seed)
    }

    public init(state: GameState, seed: UInt64 = .random(in: 0...UInt64.max)) {
        self.state = state
        rng = SplitMix64(seed: seed)
        self.state.migrate()
    }

    // MARK: Day start

    /// Fills in today's weather, demand and candidates if missing, and queues Hezarfen's lessons.
    public mutating func startDay() {
        if state.weather == nil { state.weather = newWeather() }
        if state.demand == nil { state.demand = dayDemand() }
        if state.candidates.isEmpty { newCandidates() }
        if state.rivalPlanDay != state.day { planRivalFlights() }
        printPaper()
        flagReturnCheck()
        scheduleEvent()
        unlockCheck()
        assignPilots()
        rollLatePilot()
        // The wind mast's forecast is made in the morning, so the town can show it.
        if state.level(.mast) >= 2 { _ = forecast() }
    }

    func demandGrowth() -> Double { 1 + 0.6 * (1 - exp(-Double(state.day - 1) / 50)) }

    mutating func dayDemand() -> Int {
        let flag = state.weather?.flag ?? .green
        return jsRound(Double(state.demandBase) * demandGrowth() * rng.range(0.85, 1.15) * flag.demand * (state.winter != nil ? 0.55 : 1)
                       * (state.fiesta != nil ? state.region.fiestaDemand : 1) * (state.festival != nil ? Rules.festivalDemand : 1)
                       * state.salesFactor * (1 + 0.01 * Double(state.decorationCount)) * holdingBoost(state.region))
    }

    mutating func newWeather() -> Weather {
        // The wind mast's forecast, once made, comes true.
        var flag: Flag = state.day == 1 ? .green : state.forecast?[state.day] ?? rollFlag()
        // The first days never ground a beginner.
        if flag == .red && state.day <= 3 { flag = .yellow }
        let surf = flag == .green ? rng.range(3, 10) : flag == .yellow ? rng.range(11, 18) : rng.range(19, 30)
        var l = [(rng.chance(0.5) ? -1.0 : 1.0) * surf / 3.6 * 0.45,
                 rng.range(-4, 4) * flag.wind, rng.range(-6, 6) * flag.wind, rng.range(-8, 8) * flag.wind]
        if state.region.boxWinds {
            l = [-rng.range(2, 4) * flag.wind, rng.range(3, 5.5) * flag.wind, -rng.range(1, 3.5) * flag.wind, rng.range(4, 7) * flag.wind]
        } else if state.region.nileWinds {
            l = [rng.range(1.5, 3.5) * flag.wind, -rng.range(2, 4.5) * flag.wind, rng.range(2.5, 5) * flag.wind, -rng.range(3, 6) * flag.wind]
        }
        // Always leave one layer that carries you east and one that brings you back.
        if !l.contains(where: { $0 > 3 }) { l[1 + rng.int(3)] = rng.range(3.5, 6) * flag.wind }
        if !l.contains(where: { $0 < -0.5 }) {
            var m = 0
            for (i, v) in l.enumerated() where v < 3 && (l[m] >= 3 || v < l[m]) { m = i }
            l[m] = -rng.range(1, 4) * flag.wind
        }
        let target = 220 + (state.region.boxWinds ? rng.range(1000, 1700) : rng.range(1300, 2100))
        // Festivals always bring a special request.
        var mission: Mission? = state.day <= 2 || (rng.chance(0.4) && !(state.festival != nil && flag != .red)) ? nil
            : (flag == .yellow && rng.chance(0.5) ? .precision : rng.pick(Mission.allCases))
        if !state.firstMissionGiven && state.day >= 3 && flag != .red {
            mission = .proposal
            state.firstMissionGiven = true
        } else if !state.firstMissionGiven {
            mission = nil
        }
        return Weather(flag: flag, surfaceWind: jsRound(surf), layers: l, target: target, seed: rng.next(),
                       mission: mission, valley: 220 + (target - 220) * rng.range(0.35, 0.6))
    }

    mutating func newCandidates() {
        func make(_ level: PilotLevel, school: Bool = false) -> Pilot {
            let initial = Character(UnicodeScalar(65 + rng.int(26))!)
            defer { state.nextID += 1 }
            return Pilot(id: state.nextID, name: "\(rng.pick(state.region.pilotNames)) \(initial).", level: level, fromSchool: school, trait: rollTrait())
        }
        state.candidates = []
        for _ in 0..<3 {
            let r = rng.unit()
            state.candidates.append(make(r < 0.5 ? .rookie : r < 0.85 ? .experienced : .senior))
        }
        if state.school { state.candidates.insert(make(rng.chance(0.3) ? .experienced : .rookie, school: true), at: 0) }
    }

    mutating func queueTip(_ t: Tip) {
        if !state.tipsSeen.contains(t) && !state.hezQueue.contains(.tip(t)) { state.hezQueue.append(.tip(t)) }
    }

    mutating func unlockCheck() {
        let s = state
        // One new building every two days, so each lesson lands before the next.
        let rules: [Feature: Bool] = [
            .insurance: s.day >= 2, .fleet: s.day >= 4 || s.cash >= 7000, .bank: s.day >= 6,
            .market: s.day >= 8, .crew: s.balloons.count >= 2 || s.day >= 10
        ]
        let tipFor: [Feature: Tip] = [.insurance: .insurance, .fleet: .fleet, .bank: .bank, .market: .market, .crew: .crew]
        for f in Feature.allCases where rules[f]! && !state.unlocked.contains(f) {
            state.unlocked.insert(f)
            queueTip(tipFor[f]!)
        }
        queueTip(.welcome)
        if s.day >= 3 { queueTip(.goals) } // day 3: day 2 already teaches insurance and often the yellow flag
        if s.day >= 3 { bossSay(.hello) }
        if s.day >= 9 { queueTip(.pr) }
        if s.unlocked.contains(.market) && s.day >= 11 { queueTip(.bazaar) }
        if s.weather?.flag == .yellow { queueTip(.yellow) }
        if s.weather?.flag == .red { queueTip(.red) }
        if s.weather?.mission != nil { queueTip(.mission) }
        if s.rep < Rules.crisisRep { queueTip(.crisis) }
        if s.balloons.contains(where: { s.condition($0) < 0.3 }) { queueTip(.aging) }
        inspect()
        if s.stars > 4.5 { queueTip(.expect) }
        if s.unlocked.contains(.market) {
            if s.day >= 10 { queueTip(.rivals) }
            if s.day >= 13 { queueTip(.rivals2) }
            if s.day >= 16 { queueTip(.rivals3) }
        }
        if s.balloons.contains(where: { $0.damagedUntil > s.day }) { queueTip(.accident) }
        if !s.licenseValid { queueTip(.licenseHold) }
        // Once the fleet has grown: you may hand the flagship to a pilot (but keep the license and the passengers in mind).
        if s.day >= 7 && s.tipsSeen.contains(.crew) && s.balloons.count >= 2 && s.local.selfFly && s.licenseValid { queueTip(.delegate) }
        // No rival flew, yet seats stayed empty because the price was high: tourists still weigh the price.
        if !s.rivals.contains(where: \.alive), let ls = s.local.lastShare, ls.cap > 0, ls.me < ls.cap,
           Rules.willing(Double(s.price)) < 0.85 { queueTip(.noRivals) }
    }

    /// The inspector comes by when an envelope is below 30%: two warnings five days apart, then a fine each visit.
    mutating func inspect() {
        let worn = state.balloons.filter { state.condition($0) < 0.3 && state.condition($0) > 0 }
        guard !worn.isEmpty else { state.inspectCount = 0; return }
        if state.day - (state.inspectDay ?? -99) < 5 { return }
        if state.hezQueue.contains(where: { if case .inspector = $0 { return true }; return false }) { return }
        let n = (state.inspectCount ?? 0) + 1
        state.inspectDay = state.day
        state.inspectCount = n
        var fine = 0
        if n >= 3 {
            fine = 2500 * worn.count
            state.cash -= fine
            addPaper(.inspectorFine(fine: fine))
        }
        state.hezQueue.append(.inspector(visit: min(n, 3), balloons: worn.map(\.name), fine: fine))
    }

    /// Pops the next Hezarfen message and marks lessons as seen.
    public mutating func nextHezarfen() -> HezMessage? {
        guard !state.hezQueue.isEmpty else { return nil }
        let m = state.hezQueue.removeFirst()
        if case .tip(let t) = m { state.tipsSeen.insert(t) }
        return m
    }

    public mutating func replayRivalTips() {
        state.hezQueue.append(contentsOf: [.tip(.rivals), .tip(.rivals2), .tip(.rivals3)])
    }

    /// Best pilots go to the biggest balloons that can fly; balloons in repair or with a worn
    /// envelope come last. The flagship is yours while you fly it yourself.
    public mutating func assignPilots() {
        var bs = state.balloons
        for i in bs.indices { bs[i].pilot = nil }
        let s = state
        func down(_ b: Balloon) -> Int { b.damagedUntil > s.day || s.condition(b) <= 0 ? 1 : 0 }
        let need = bs.indices
            .filter { !(bs[$0].id == s.flagship && s.flyingSelf) }
            .sorted { (down(bs[$0]), -bs[$0].size.capacity) < (down(bs[$1]), -bs[$1].size.capacity) }
        let ps = s.pilots.sorted { ($0.level.rawValue, $0.xp) > ($1.level.rawValue, $1.xp) }
        for (k, i) in need.enumerated() where k < ps.count { bs[i].pilot = ps[k].id }
        state.balloons = bs
    }

    mutating func planRivalFlights() {
        let flag = state.weather?.flag ?? .green
        state.rivalPlanDay = state.day
        for i in state.rivals.indices {
            var r = state.rivals[i]
            r.flyToday = []
            if r.alive {
                let go: Double = flag == .green ? 1 : flag == .yellow ? (r.style == .safe ? 0.5 : 1)
                    : (r.style == .risky && rng.chance(0.5) ? 1 : 0)
                let avail = r.balloons.indices.filter { r.damagedUntil[$0] <= state.day }
                r.flyToday = go == 1 ? avail : go == 0.5 ? avail.enumerated().filter { $0.offset % 2 == 0 }.map(\.element) : []
            }
            state.rivals[i] = r
        }
    }

    // MARK: Risk and insurance

    public func accidentChance(_ b: Balloon) -> Double {
        let flag = state.weather?.flag ?? .green
        let pilotRisk = state.isSelf(b) ? 1 : state.pilot(of: b)?.level.risk ?? 1
        let traitRisk = trait(of: b)?.accidentFactor ?? 1
        let radar = flag == .yellow && state.level(.mast) >= 3 ? 0.8 : 1
        let equipment = Burners.risk[b.burners - 1] * (b.hasTurningVent && flag != .green ? Burners.turningVentRisk : 1)
        return equipment * flag.accident * traitRisk * radar * pilotRisk * b.size.risk * (state.condition(b) < 0.3 ? 1.5 : 1)
    }

    /// Daily premiums for one balloon given its accident chance. Nothing is insurable on a red day.
    public func premium(_ size: BalloonSize, chance p: Double) -> (hull: Int, pax: Int) {
        if state.weather?.flag == .red { return (0, 0) }
        let cost = Double(size.cost), cap = Double(size.capacity)
        return (jsRound(max(cost * 0.001, p * cost * 0.21 * 1.3)), jsRound(max(cap * 2, p * cap * 1500 * 1.3)))
    }

    public func premiums() -> (hull: Int, pax: Int) {
        state.flyingToday.reduce((0, 0)) { acc, b in
            let q = premium(b.size, chance: accidentChance(b))
            return (acc.0 + q.hull, acc.1 + q.pax)
        }
    }
}
