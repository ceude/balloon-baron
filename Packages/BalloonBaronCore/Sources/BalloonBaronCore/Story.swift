import Foundation

// The town's stories: the morning paper, rival bosses, morning events, Cappadocia's festivals and the night.
// Text for all of it lives in the app's string catalog; the core only holds ids and values.

// MARK: Morning paper

/// One headline. The biggest stories lead; the paper only comes out when something happened.
/// Text: `paper.<kind>.head` / `paper.<kind>.sub`.
public struct PaperItem: Codable, Equatable, Sendable {
    public var priority: Int
    public var story: Story
}

public enum Story: Codable, Equatable, Sendable {
    case myAccident(balloon: String, days: Int, severe: Bool)
    case redCaught(fine: Int)
    case antitrust(sharePercent: Int, fine: Int)
    case seized(balloon: String)
    case record(pax: Int)
    case passedBoss(rival: String)
    case festival(Festival)
    case newEntrant(rival: String)
    case rivalAccident(rival: String, count: Int)
    case rivalRedFine(rival: String, fine: Int)
    case hotelLost(Hotel, rival: String)
    case rivalBankrupt(rival: String, balloons: Int)
    case upgrade(Building, level: Int)
    case night(NightEvent)
    case worldBaron
    case vip, wedding, documentary, pressGood, pressBad
}

// MARK: Rival bosses

/// What the boss of the region's oldest company says, once each. Text: `boss.<region>.<rawValue>`.
public enum BossLine: String, Codable, CaseIterable, Sendable {
    case hello, ch1, ch2, passed, hotel, poach, accident, deal, gone, baron
}

extension RegionID {
    /// The company whose owner talks to you.
    public var bossCompany: String { self == .abq ? "Sandia Sky Rides" : "Göreme Sky" }
}

// MARK: Festivals

/// Cappadocia's festivals: three busy days about every five weeks, never in winter. Name: `festival.<rawValue>`.
public enum Festival: String, Codable, CaseIterable, Sendable {
    case harvest, holiday, lights

    public static let firstDay = 24, every = 35, days = 3
    public static let demand = 1.4, missionBonus = 1.5

    public struct Running: Codable, Equatable, Sendable {
        public var kind: Festival, start: Int, end: Int
    }
}

// MARK: Morning events

/// About once a week something happens at one of your buildings and you decide. Text: `event.<rawValue>.*`.
public enum MorningEvent: String, Codable, CaseIterable, Sendable {
    case strike, vip, wedding, doc, fuel, press

    public static let firstDay = 12
}

/// What came of a morning event. Hezarfen's comment: `event.<event>.<rawValue>`.
public enum EventOutcome: String, Codable, Sendable {
    case raise, holdOut, accepted, declined, stocked, paidRise, pressGood, pressBad
}

// MARK: Night

/// Something that lights up a night now and then. Text: `night.<kind>`.
public enum NightEvent: Codable, Equatable, Sendable {
    case lanterns(Festival)
    case glow
    case snow
    case fireworks(Hotel)
    case shooting
}

extension Game {
    // MARK: Paper

    mutating func paperAdd(_ priority: Int, _ story: Story) {
        state.paperNext.append(PaperItem(priority: priority, story: story))
    }

    /// Today's paper, biggest story first, at most three. Empty when nothing happened.
    public var todaysPaper: [PaperItem] {
        Array(state.paper.enumerated().sorted { ($0.element.priority, -$0.offset) > ($1.element.priority, -$1.offset) }.map(\.element).prefix(3))
    }

    public mutating func foldPaper() { state.paper = [] }

    // MARK: Bosses

    /// The boss's company, while it still flies under its own name.
    public var bossRival: Rival? { state.rivals.first { $0.name == state.region.bossCompany } }

    /// Queue a boss line once per region.
    public mutating func bossSay(_ line: BossLine) {
        let id = "\(state.region.rawValue).\(line.rawValue)"
        guard !state.bossSaid.contains(id) else { return }
        state.bossSaid.insert(id)
        state.hezQueue.append(.boss(state.region, line))
    }

    /// Said when you start the next chapter, if the boss is still in business.
    public mutating func bossChapterLine(_ index: Int) {
        guard bossRival?.alive == true else { return }
        if index == 1 { bossSay(.ch1) } else if index == 2 { bossSay(.ch2) }
    }

    // MARK: Morning events

    func spareBalloon() -> Balloon? {
        state.balloons.filter { $0.id != state.flagship && state.status($0) == .ok }.max { $0.size.capacity < $1.size.capacity }
    }

    public func eventAvailable(_ e: MorningEvent) -> Bool {
        switch e {
        case .strike: return state.pilots.count >= 2
        case .vip, .wedding: return spareBalloon() != nil
        case .doc: return state.balloon(state.flagship).map { state.status($0) == .ok } ?? false
        case .fuel: return state.balloons.count >= 2
        case .press: return true
        }
    }

    /// Picks the morning event to show (never the same as last time) and clears the due flag.
    public mutating func drawMorningEvent() -> MorningEvent? {
        state.eventDue = false
        let keys = MorningEvent.allCases.filter { eventAvailable($0) && $0 != state.lastEvent }
        guard !keys.isEmpty else { return nil }
        let e = rng.pick(keys)
        state.lastEvent = e
        return e
    }

    /// The balloon a VIP or wedding party wants, and what they pay up front.
    public func charterOffer(_ e: MorningEvent) -> (balloon: Balloon, pay: Int)? {
        guard let b = spareBalloon() else { return nil }
        let k = e == .vip ? 2.2 : 1.4
        return (b, jsRound(Double(b.size.capacity * state.price) * k / 50) * 50)
    }

    /// What the strikers' 15% raise adds to the daily wage bill.
    public var strikeRaise: Int { state.pilots.reduce(0) { $0 + raised($1) - $1.wage } }
    func raised(_ p: Pilot) -> Int { jsRound(Double(p.wage) * 1.15 / 5) * 5 }
    public var wageBill: Int { state.pilots.reduce(0) { $0 + $1.wage } }

    /// Stocking up on propane now, before the five-day price rise.
    public var fuelStockCost: Int { jsRound(Double(state.balloons.reduce(0) { $0 + $1.size.fuel }) * 5 * 0.25 / 50) * 50 }

    /// Carries out a morning event decision. `accept` is the main (top) choice.
    @discardableResult
    public mutating func resolveEvent(_ e: MorningEvent, accept: Bool) -> EventOutcome {
        var out = EventOutcome.declined
        switch (e, accept) {
        case (.strike, true):
            for i in state.pilots.indices { state.pilots[i].customWage = raised(state.pilots[i]) }
            out = .raise
        case (.strike, false):
            state.strikeDay = state.day
            state.rep -= 0.02
            state.selfFly = true
            assignPilots()
            out = .holdOut
        case (.vip, true), (.wedding, true):
            guard let o = charterOffer(e) else { break }
            state.cash += o.pay
            state.charter = Charter(day: state.day, balloon: o.balloon.id)
            state.rep += e == .vip ? 0.02 : 0.015
            addReview(e == .vip ? .perfect : .good)
            paperAdd(2, e == .vip ? .vip : .wedding)
            out = .accepted
        case (.doc, true):
            state.docDay = state.day
            state.rep += 0.06
            paperAdd(3, .documentary)
            out = .accepted
        case (.fuel, true):
            let c = fuelStockCost
            guard state.cash >= c else { break }
            state.cash -= c
            out = .stocked
        case (.fuel, false):
            state.fuelUpUntil = state.day + 4
            out = .paidRise
        case (.press, true):
            if rng.chance(0.65) {
                state.rep += 0.05
                paperAdd(3, .pressGood)
                out = .pressGood
            } else {
                state.rep -= 0.03
                paperAdd(3, .pressBad)
                out = .pressBad
            }
        default: break
        }
        if out != .declined && out != .paidRise { state.hezQueue.insert(.eventOutcome(e, out), at: 0) }
        return out
    }

    // MARK: Rescue plan

    /// The smallest balloon you could sell to get back above zero (never the flagship).
    public var rescueSale: Balloon? {
        state.balloons.filter { $0.id != state.flagship }.min { $0.size.cost < $1.size.cost }
    }

    /// A price just under the cheapest rival, when yours isn't already there.
    public var rescuePrice: Int? {
        let cheap = (state.rivals.filter(\.alive).map(\.price) + [state.price]).min() ?? state.price
        return state.price > cheap - 5 ? max(Rules.priceRange.lowerBound, cheap - 10) : nil
    }

    /// The biggest loan you can still take, as an index into `Rules.loans`.
    public var rescueLoan: Int? {
        guard state.unlocked.contains(.bank), state.loans.count < Rules.maxLoans else { return nil }
        return Rules.loans.indices.reversed().first { state.balloons.count >= Rules.loans[$0].balloonsNeeded }
    }

    public mutating func fireIdlePilots() {
        let idle = Set(state.idlePilots.map(\.id))
        state.pilots.removeAll { idle.contains($0.id) }
        assignPilots()
    }

    /// Shown once each time cash goes below zero.
    public var rescueDue: Bool { state.cash < 0 && !state.rescueShown }
    public mutating func markRescueShown() { state.rescueShown = true }
    /// Back above zero: Hezarfen says well done and the plan can come again next time.
    public mutating func checkRescued() {
        if state.cash >= 0 && state.rescueShown {
            state.rescueShown = false
            state.hezQueue.insert(.rescued, at: 0)
        }
    }

    // MARK: Night

    /// Picks what happens tonight, if anything, and puts it in tomorrow's paper.
    public mutating func startNight() -> NightEvent? {
        var ev: NightEvent?
        if let f = state.festival {
            ev = .lanterns(f.kind)
        } else if state.fiesta != nil {
            ev = .glow
        } else if let w = state.winter, state.winterNight != w.start {
            state.winterNight = w.start
            ev = .snow
        } else {
            let r = rng.unit()
            if r < 0.22 { ev = .fireworks(rng.pick(Hotel.allCases)) } else if r < 0.32 { ev = .shooting }
        }
        if let ev { paperAdd(ev == .shooting ? 1 : 2, .night(ev)) }
        return ev
    }
}
