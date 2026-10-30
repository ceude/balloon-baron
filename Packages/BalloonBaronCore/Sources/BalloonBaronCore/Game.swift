import Foundation

/// The whole simulation. A value type: the app keeps one in an observable store and saves `state`.
public struct Game: Sendable {
    public var state: GameState
    var rng: SplitMix64
    /// v124.6: popularity changes by reason while `finishDay` runs (`rep(_:_:)`).
    var repLog: [RepReason: Double]?

    public init(company: String, colors: [String], seed: UInt64 = .random(in: 0...UInt64.max)) {
        state = GameState(company: company, colors: colors)
        rng = SplitMix64(seed: seed)
    }

    public init(state: GameState, seed: UInt64 = .random(in: 0...UInt64.max)) {
        self.state = state
        rng = SplitMix64(seed: seed)
        self.state.migrate()
        tutorialCheck()
    }

    // MARK: Day start

    /// Fills in today's weather, demand and candidates if missing, and queues Hezarfen's lessons.
    public mutating func startDay() {
        expireSeasons()
        if state.weather == nil { state.weather = newWeather() }
        // v122.4: day 2 of the fixed scenario starts at €160, once, so raising the price keeps the basket full
        if state.tutorialScene == 2 && !state.tutorialHas("price2_start") {
            state.price = TutorialScene.dayTwoPrice
            var t = state.tutorial ?? TutorialState()
            t.steps["price2_start"] = state.day
            state.tutorial = t
        }
        if state.demand == nil { state.demand = dayDemand() }
        if state.candidates.isEmpty { newCandidates() }
        if state.rivalPlanDay != state.day { planRivalFlights() }
        printPaper()
        flagReturnCheck()
        contractTidy()
        scheduleEvent()
        unlockCheck()
        assignPilots()
        rollLatePilot()
        spreadMorning()
        // The wind mast's forecast is made in the morning, so the town can show it.
        if state.level(.mast) >= 2 { _ = forecast() }
    }

    func demandGrowth() -> Double { 1 + 0.6 * (1 - exp(-Double(state.day - 1) / 50)) }

    mutating func dayDemand() -> Int {
        if let d = TutorialScene.demand[state.tutorialScene] { return d }
        let flag = state.weather?.flag ?? .green
        return jsRound(Double(state.demandBase) * demandGrowth() * rng.range(0.85, 1.15) * flag.demand * (state.winter != nil ? 0.55 : 1)
                       * (state.fiesta != nil ? state.region.fiestaDemand : 1) * (state.festival != nil ? Rules.festivalDemand : 1)
                       * state.salesFactor * holdingBoost(state.region))
    }

    mutating func newWeather() -> Weather {
        let sc = state.tutorialScene
        if sc > 0, let l = TutorialScene.layers[sc], let tx = TutorialScene.target[sc] {
            return Weather(flag: .green, surfaceWind: TutorialScene.surfaceWind[sc] ?? 5, layers: l, target: tx,
                           seed: UInt64(7700 + sc), mission: nil, valley: 220 + (tx - 220) * 0.45)
        }
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
        } else if state.region.westWinds {
            // v124: west wind off the Bristol Channel, east at mid heights
            l = [rng.range(-2.5, 1.5) * flag.wind, rng.range(2.5, 5) * flag.wind, rng.range(3, 6) * flag.wind,
                 (rng.chance(0.5) ? -rng.range(1, 4) : rng.range(1, 3)) * flag.wind]
        }
        // Always leave one layer that carries you east and one that brings you back.
        if !l.contains(where: { $0 > 3 }) { l[1 + rng.int(3)] = rng.range(3.5, 6) * flag.wind }
        if !l.contains(where: { $0 < -0.5 }) {
            var m = 0
            for (i, v) in l.enumerated() where v < 3 && (l[m] >= 3 || v < l[m]) { m = i }
            l[m] = -rng.range(1, 4) * flag.wind
        }
        // v124: Bristol's field is nearer, like Albuquerque's (`cap ? 1300–2100 : 1000–1700` in the prototype).
        // v124.6: in Cappadocia the field is still close on day 3 (days 1-2 are the fixed scenario)
        let target = 220 + (state.region.boxWinds || state.region.bristol ? rng.range(1000, 1700)
            : state.region == .cap && state.day <= 3 ? rng.range(1000, 1250) : rng.range(1300, 2100))
        // Festivals always bring a special request.
        var mission: Mission? = state.day <= 2 || (rng.chance(0.4) && !(state.festival != nil && flag != .red)) ? nil
            : (flag == .yellow && rng.chance(0.5) ? .precision : rng.pick(Mission.allCases))
        if !state.firstMissionGiven && state.day >= 3 && flag != .red {
            mission = .proposal
            state.firstMissionGiven = true
        } else if !state.firstMissionGiven {
            mission = nil
        }
        var w = Weather(flag: flag, surfaceWind: jsRound(surf), layers: l, target: target, seed: rng.next(),
                        mission: mission, valley: 220 + (target - 220) * rng.range(0.35, 0.6))
        // v124: Bristol: morning fog on about a quarter of the flyable days (the field shows only under its top), and on
        // ~40% of days the airport's controlled airspace over part of the way (above its floor: warning, then a fine).
        if state.region.bristol && flag != .red {
            if rng.chance(0.28) { w.fog = Fog(top: Double(jsRound(rng.range(90, 150)))) }
            if rng.chance(0.4) {
                let x0 = 220 + rng.range(380, max(420, target - 220 - 760))
                w.air = Airspace(x0: Double(jsRound(x0)), x1: Double(jsRound(x0 + rng.range(420, 620))), floor: Double(jsRound(rng.range(340, 410))))
            }
        }
        return w
    }

    mutating func newCandidates() {
        func make(_ level: PilotLevel, school: Bool = false) -> Pilot {
            let initial = rng.pick(state.region.pilotInitials)
            defer { state.nextID += 1 }
            let name = "\(rng.pick(state.region.pilotNames)) \(initial).", trait = rollTrait()
            // v124: Bristol's wages are 15% higher; the region's wage is fixed when the pilot is hired.
            let wage = state.region.wageFactor != 1 ? Pilot.baseWage(level, school: school, trait: trait, region: state.region) : nil
            return Pilot(id: state.nextID, name: name, level: level, fromSchool: school, customWage: wage, trait: trait)
        }
        state.candidates = []
        for _ in 0..<3 {
            let r = rng.unit()
            state.candidates.append(make(r < 0.5 ? .rookie : r < 0.85 ? .experienced : .senior))
        }
        if state.school { state.candidates.insert(make(rng.chance(0.3) ? .experienced : .rookie, school: true), at: 0) }
    }

    /// v121.12: nobody reads seven cards in a row. A morning shows at most `Rules.morningLessons` of Hezarfen's lessons
    /// and one postcard; the rest wait for the next mornings, in order. News, rivals and the inspector aren't held back.
    /// v121.13 (TestFlight: "Balloon Fiesta, day 44/4"): a region you were away from keeps its last fiesta, festival or
    /// winter, since they only end at the close of a day played there. On coming back, the ones that are over end quietly.
    mutating func expireSeasons() {
        if let f = state.fiesta, state.day > f.end {
            state.fiesta = nil
            state.fiestaNext = state.day + state.region.fiestaEvery
        }
        if let f = state.festival, state.day > f.end { state.festival = nil }
        if let w = state.winter, state.day > w.end {
            state.winter = nil
            state.nextWinter = state.day + 45
        }
    }

    mutating func spreadMorning() {
        guard state.day >= 2, state.spreadDay != state.day else { return }
        state.spreadDay = state.day
        var keep: [HezMessage] = [], later: [HezMessage] = [], n = 0
        var q = (state.hezLater ?? []) + state.hezQueue
        // v122.11: day 3's price reminder comes first, ahead of the lesson cap, and says what `price` would
        if q.contains(.tip(.price3)) { q = [.tip(.price3)] + q.filter { ![.tip(.price3), .tip(.price), .tip(.priceRep), .tip(.priceRiv)].contains($0) } }
        for m in q {
            var lesson = false
            if case .tip = m { lesson = true } // praise has its own every-other-day pace
            if lesson { n += 1 }
            if lesson && n > Rules.morningLessons { later.append(m) } else { keep.append(m) }
        }
        state.hezQueue = keep
        state.hezLater = later
        let posts = (state.postcardsLater ?? []) + (state.newPostcards ?? [])
        state.newPostcards = Array(posts.prefix(1))
        state.postcardsLater = Array(posts.dropFirst())
    }

    mutating func queueTip(_ t: Tip) {
        if !state.tipsSeen.contains(t) && !state.hezQueue.contains(.tip(t)) && !(state.hezLater ?? []).contains(.tip(t)) { state.hezQueue.append(.tip(t)) }
    }

    mutating func unlockCheck() {
        // v121.9 (TestFlight: days with nothing new felt empty): something opens every day from day 2 to day 11. A save
        // from before keeps the buildings that its pages used to bring, without a burst of lessons.
        if state.unlockVersion == nil {
            if state.unlocked.contains(.market) { state.unlocked.formUnion([.guide, .agency, .bazaar]) }
            if state.unlocked.contains(.fleet) { state.unlocked.insert(.workshop) }
            if state.unlocked.contains(.crew) { state.unlocked.insert(.school) }
            state.unlockVersion = 2
        }
        let s = state
        func at(_ f: Feature) -> Bool { s.day >= Rules.unlockDay[f]! }
        let rules: [Feature: Bool] = [
            .insurance: at(.insurance), .fleet: at(.fleet) || s.cash >= 7000, .bank: at(.bank),
            .crew: s.balloons.count >= 2 || at(.crew), .market: at(.market), .guide: at(.guide), .agency: at(.agency),
            .bazaar: at(.bazaar), .workshop: at(.workshop), .school: at(.school)
        ]
        let tipFor: [Feature: Tip] = [.insurance: .insurance, .fleet: .fleet, .bank: .bank, .market: .market, .crew: .crew,
                                      .guide: .guide, .agency: .agency, .bazaar: .bazaar, .workshop: .workshop, .school: .school]
        for f in Feature.allCases where rules[f]! && !state.unlocked.contains(f) {
            state.unlocked.insert(f)
            queueTip(tipFor[f]!)
        }
        queueTip(.welcome)
        if s.day >= 3 { queueTip(.goals) } // day 3: day 2 already teaches insurance and often the yellow flag
        if s.day >= (s.region == .cap ? 1 : 3) { bossSay(.hello) } // v121: Kenan greets Hasan's grandchild on the first morning
        if s.unlocked.contains(.guide) { queueTip(.pr) }
        // v111: a TestFlight player left seats empty without noticing the price; the morning after, Hezarfen shows it.
        // v124.6: and says why: a dear ticket, low stars against the rivals, or more seats than tourists
        if s.day >= 2 && s.day <= 12, let l = s.local.lastShare, l.cap > 0, l.me < l.cap { queueTip(emptySeatCause) }
        // v122.11: day 2's crowd made the player raise the price; on day 3 the tourists are back to normal, so Hezarfen
        // says to set it for today (a player who kept day 2's price flew half empty for days in tools/sim).
        if s.day == 3 && s.region == .cap, let t = s.tutorial, !t.isOld { queueTip(.price3) }
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
        // v117: the autopilot opens.
        if s.autopilotOK { queueTip(.autopilot) }
        // No rival flew, yet seats stayed empty because the price was high: tourists still weigh the price.
        if !s.rivals.contains(where: \.alive), let ls = s.local.lastShare, ls.cap > 0, ls.me < ls.cap,
           Rules.willing(Double(s.price)) < 0.85 { queueTip(.noRivals) }
        // v111: on a quiet morning, with seats to spare and cash for three, Hezarfen suggests a Balloon Show.
        if showState == .ok, s.cash >= showCost * 3, state.hezQueue.isEmpty, s.eventDue != true, s.winter == nil, s.day >= 14,
           let ls = s.local.lastShare, ls.cap > 0, Double(ls.me) < Double(ls.cap) * 0.9 { queueTip(.show) }
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
        // v121.12: a praise that's no longer true (the pilot was let go) is dropped
        while let first = state.hezQueue.first, case .praise(let p) = first, !praiseStillTrue(p) { state.hezQueue.removeFirst() }
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
    /// v124.4: the player's pins come first; a pin whose pilot left is dropped. While the pinned balloon is in repair,
    /// its envelope is done or the founder flies it, the pin stays and the pilot helps out on another balloon that day.
    /// Everyone else is placed as before: the most senior pilot on the biggest balloon.
    public mutating func assignPilots() {
        var bs = state.balloons
        for i in bs.indices { bs[i].pilot = nil }
        let s = state
        func down(_ b: Balloon) -> Int { b.damagedUntil > s.day || s.condition(b) <= 0 ? 1 : 0 }
        func isSelf(_ b: Balloon) -> Bool { b.id == s.flagship && s.flyingSelf }
        let ids = Set(s.pilots.map(\.id))
        var pinned = Set<Int>()
        for i in bs.indices {
            guard let p = bs[i].pinnedPilot else { continue }
            if pinned.contains(p) || !ids.contains(p) { bs[i].pinnedPilot = nil; continue }
            pinned.insert(p)
            if !isSelf(bs[i]) && down(bs[i]) == 0 { bs[i].pilot = p }
        }
        let used = Set(bs.compactMap(\.pilot))
        let need = bs.indices
            .filter { !isSelf(bs[$0]) && bs[$0].pilot == nil }
            .sorted { (down(bs[$0]), -bs[$0].size.capacity) < (down(bs[$1]), -bs[$1].size.capacity) }
        let ps = s.pilots.filter { !used.contains($0.id) }.sorted { ($0.level.rawValue, $0.xp) > ($1.level.rawValue, $1.xp) }
        for (k, i) in need.enumerated() where k < ps.count { bs[i].pilot = ps[k].id }
        state.balloons = bs
    }

    /// v124.4: puts pilot `pilot` on balloon `balloon`. If that pilot was on another balloon (pinned or placed), the two
    /// swap: that balloon gets this balloon's pilot. A nil pilot hands the balloon back to the morning's placing.
    public mutating func pinPilot(balloon: Int, pilot: Int?) {
        guard let bi = state.balloons.firstIndex(where: { $0.id == balloon }) else { return }
        guard let p = pilot, state.pilots.contains(where: { $0.id == p }) else {
            state.balloons[bi].pinnedPilot = nil
            assignPilots()
            return
        }
        let old = state.balloons[bi].pilot ?? state.balloons[bi].pinnedPilot
        let other = state.balloons.firstIndex { $0.id != balloon && ($0.pinnedPilot == p || $0.pilot == p) }
        for i in state.balloons.indices where state.balloons[i].pinnedPilot == p { state.balloons[i].pinnedPilot = nil }
        state.balloons[bi].pinnedPilot = p
        if let o = other {
            let back = old.flatMap { q in q != p && state.pilots.contains { $0.id == q } ? q : nil }
            state.balloons[o].pinnedPilot = back
        }
        assignPilots()
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
