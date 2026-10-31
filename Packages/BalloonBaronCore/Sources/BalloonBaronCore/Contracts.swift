import Foundation

// v125–v125.3: corporate contracts (`CTR` in the prototype). Now and then a morning a local company's owner offers a
// group at a price below the market: tour coaches in Albuquerque (one day), Nile cruise ships in Luxor (a block of
// mornings), London weekend trains in Bristol (Saturday and Sunday, with a fog guarantee). Each region has its own cast
// of three owners; saying no, or not delivering, sends the group to the most popular rival, who grows with it.
// v126: Cappadocia's charter flights (two mornings, a plane that may be late).

/// What stands at the off-map place and brings the group: coaches, a cruise ship, a steam train or (v126) a charter plane.
public enum ContractKind: String, Codable, Sendable {
    case bus, ship, train, plane
}

/// The owners of the contract companies, three per region (`CTR_CAST_*`). Their names, titles and lines live in the
/// string catalog under `ctr.<rawValue>.*`; the company names are proper names, like the rivals'.
public enum ContractOwner: String, Codable, CaseIterable, Sendable {
    case rosa, hank, linda
    case farouk, dalia, hamza
    case nigel, priya, fiona
    case jiwoo, chen, murat

    public var company: String {
        switch self {
        case .rosa: "Mother Road Coaches"
        case .hank: "Turquoise Mesa Tours"
        case .linda: "High Desert Coachlines"
        case .farouk: "Sobek Nile Cruises"
        case .dalia: "Golden Lotus Line"
        case .hamza: "Dahabiya Pearl"
        case .nigel: "West Country Weekenders"
        case .priya: "Capital Rail Breaks"
        case .fiona: "Steam & Sky Excursions"
        case .jiwoo: "Haneul Wings"
        case .chen: "Pearl Bund Travel"
        case .murat: "Haliç Gündoğumu Turları"
        }
    }

    /// The owner's color (their vehicle's stripe, their name tag).
    public var color: String {
        switch self {
        case .rosa: "#2ab0a8"
        case .hank: "#8a5aa8"
        case .linda: "#e0408a"
        case .farouk: "#1f6f8b"
        case .dalia: "#c9a040"
        case .hamza: "#e0408a"
        case .nigel: "#2a5a3a"
        case .priya: "#7a2a8a"
        case .fiona: "#c0392b"
        case .jiwoo: "#e0408a"
        case .chen: "#c0392b"
        case .murat: "#1f6f8b"
        }
    }
}

/// What an owner says on a morning card (`ctrSay`). Text: `ctr.<owner>.<rawValue>`.
public enum ContractLine: String, Codable, Sendable {
    case today, thanks, pref, fail, lostPref, red, redSkip, redCancel, fog, bye
    /// v126: a charter plane: "it may be late" (the evening before), "it's late" (the card), "landed on time", and how
    /// the choice turned out.
    case warn, late, onTime, landed, noShow, stranded, openOk
}

/// v126: a charter plane's delay (`CTR.cap.delay`): from the job after `after` on, the evening before its first morning
/// there's a `warnP` chance of a warning; that morning it is late with `lateP`, and makes the morning with a chance in
/// `land` (rounded to 0.1). Seats kept for it that fly empty are paid at `waitPay` of the price per head.
public struct ContractDelayConfig: Sendable {
    public var after = 2
    public var warnP = 0.35, lateP = 0.6
    public var land: ClosedRange<Double> = 0.3...0.7
    public var waitPay = 0.4
}

/// The numbers per region (tuned with the prototype's simulations, see GAME_DESIGN "Kurumsal kontratlar").
public struct ContractConfig: Sendable {
    public var kind: ContractKind
    public var cast: [ContractOwner]
    /// The region's chapter index from which offers come (1: once chapter 2 starts), the fleet's seats needed, and the
    /// days after that before the first one.
    public var minChapter = 1, minSeats = 40, firstWait = 1
    /// Days between offers (as the preferred operator), days ahead an offer is for, days a booking lasts.
    public var gap: ClosedRange<Double> = 10...14, prefGap: ClosedRange<Double> = 6...9
    public var lead: ClosedRange<Double> = 3...5, len: ClosedRange<Double> = 1...1
    /// The group's share of the fleet's seats, and its price per head against the reference (your ticket and the
    /// rivals' average, halfway); the preferred operator gets a little more.
    public var share: ClosedRange<Double> = 0.4...0.7, price: ClosedRange<Double> = 0.8...0.9
    public var prefPrice = 1.06
    /// A negotiation asks this much more; the chance the company walks to a rival (less for the preferred operator).
    public var negUp = 0.1, negWalk = 0.35, prefWalk = 0.15
    /// Penalty per missing seat (share of the price per head); price cut when a red flag moves a one-day group.
    public var pen = 0.5, redCut = 0.2
    /// A red flag moves a one-day group to the next day; otherwise a red morning is skipped.
    public var redMove = true
    /// Bookings start on a Saturday (Bristol's weekends).
    public var weekend = false
    /// Bristol's fog guarantee: a foggy morning refunds the day and costs a voucher per head; the forecast's range.
    public var fogGuarantee = false
    public var voucher = 0.15
    public var fogP: ClosedRange<Double> = 0.05...0.45
    /// Jobs to become the preferred operator, the trust at which an owner breaks off, and the days before the next one.
    public var prefNeed = 3, breakAt = -3, cool = 14
    /// A rival who takes a group gains this much popularity, and a balloon for every `rivalGrow` people.
    public var rivalRep = 0.05
    public var rivalGrow = 24
    /// v126: never before this day; and not on a crowded morning (a morning event, a chapter, a merger, the fleet
    /// transfer, or more than two cards waiting): the offer waits for the next quiet one.
    public var firstDay = 0
    public var quiet = false
    /// v126: the charter plane may be late.
    public var delay: ContractDelayConfig?
    /// How close the first offer's scene looks at the place (the airport is wide).
    public var sceneZoom = 0.86

    public static func of(_ r: RegionID) -> ContractConfig? {
        switch r {
        case .cap:
            var k = ContractConfig(kind: .plane, cast: [.jiwoo, .chen, .murat])
            k.firstDay = 40; k.quiet = true
            k.gap = 11...15; k.prefGap = 7...10; k.len = 2...2; k.share = 0.25...0.4
            k.redCut = 0; k.redMove = false
            k.delay = ContractDelayConfig()
            k.sceneZoom = 0.6
            return k
        case .abq: return ContractConfig(kind: .bus, cast: [.rosa, .hank, .linda])
        case .lux:
            var k = ContractConfig(kind: .ship, cast: [.farouk, .dalia, .hamza])
            k.minSeats = 48; k.gap = 13...18; k.prefGap = 9...12; k.len = 4...6; k.share = 0.18...0.3
            k.redCut = 0; k.redMove = false; k.rivalGrow = 20
            return k
        case .bri:
            var k = ContractConfig(kind: .train, cast: [.nigel, .priya, .fiona])
            k.minSeats = 48; k.gap = 7...10; k.prefGap = 5...7; k.lead = 3...4; k.len = 2...2; k.weekend = true
            k.share = 0.25...0.4; k.price = 0.9...1; k.prefPrice = 1.04; k.fogGuarantee = true
            k.redCut = 0; k.redMove = false
            return k
        }
    }
}

extension RegionID {
    public var contracts: ContractConfig? { ContractConfig.of(self) }
}

/// An offer waiting for an answer: so many people a day, from `day` for `len` days, at `price` a head.
public struct ContractOffer: Codable, Equatable, Sendable {
    public var owner: ContractOwner
    public var n: Int
    public var price: Int
    public var day: Int
    public var len: Int
    /// Bristol: the fog forecast for each day (0.05 … 0.45).
    public var fogP: [Double]?
    /// The day it was made, and the day its card was shown.
    public var made: Int
    public var seen: Int?
    /// The first offer in the region (it comes after the scene at the off-map place).
    public var first: Bool
    /// The price can't go above this: your ticket and the reference, rounded down to 5.
    public var top: Int
    /// Already negotiated once.
    public var negotiated: Bool

    public var lastDay: Int { day + len - 1 }
    public var total: Int { n * len * price }
}

/// A booked group: yours, or a rival's (`rival`) when you said no or couldn't deliver.
public struct ContractJob: Codable, Equatable, Sendable, Identifiable {
    public var id: Int
    public var owner: ContractOwner
    public var n: Int
    public var price: Int
    public var day: Int
    public var len: Int
    public var fogP: [Double]?
    public var rival: String?
    /// Red mornings that moved a one-day group.
    public var moves = 0
    /// People flown and missing over the job, mornings flown, foggy mornings refunded.
    public var got = 0, short = 0, flown = 0, fogged = 0
    /// A rival's group paid the rival on its first day.
    public var paid = false
    /// The day its vehicle pulled in at the off-map place. v126.1: it arrives once (the first time you look on one of
    /// its days) and stays until the job is over, even when a red flag or a late plane moves the job; any value means
    /// it has arrived (a day, not a flag, so saves from v125 still load).
    public var arrived: Int?
    /// v126: the how-manyth job taken in this region (Cappadocia's planes are never late in the first two); the evening
    /// warning has been rolled, and came; today's delay.
    public var nth: Int?
    public var warnRolled: Bool?
    public var warned: Bool?
    public var delay: ContractDelay?

    public var lastDay: Int { day + len - 1 }
    public func active(on d: Int) -> Bool { d >= day && d <= lastDay }
    public var mine: Bool { rival == nil }
    public var hasArrived: Bool { arrived != nil }
}

/// v126: what you do about a late charter plane: keep its seats, or sell them on the market.
public enum DelayChoice: String, Codable, Sendable {
    case hold, open
}

/// v126: a late plane on the morning of `day`: the chance it makes the morning (0.3 … 0.7), whether it will, your choice.
public struct ContractDelay: Codable, Equatable, Sendable {
    public var day: Int
    public var chance: Double
    public var lands: Bool
    public var choice: DelayChoice?

    public init(day: Int, chance: Double, lands: Bool, choice: DelayChoice? = nil) {
        self.day = day; self.chance = chance; self.lands = lands; self.choice = choice
    }
}

/// v126: how the choice turned out. Owner's line: `ctr.<owner>.<rawValue>`.
public enum DelayOutcome: String, Codable, Sendable {
    /// Kept the seats and it landed: the group flies today.
    case landed
    /// Kept the seats, it didn't come: they fly empty, the agency pays, the group moves a day.
    case noShow
    /// Sold the seats and it landed after all: the group waits a day for nothing, trust −1.
    case stranded
    /// Sold the seats and it didn't come in time: nobody loses anything, the group moves a day.
    case openOk
}

/// v126: seats kept today for a late plane that didn't come, paid at `pay` each.
public struct ContractWait: Codable, Equatable, Sendable {
    public var day: Int
    public var n: Int
    public var pay: Int
    public var owner: ContractOwner
}

/// A finished job's vehicle waits at the off-map place until you look, then leaves (from `from`).
public struct ContractDepart: Codable, Equatable, Sendable {
    public var owner: ContractOwner
    public var n: Int
    public var from: Int
    /// v126.1: it has started to leave (once: if the app restarts before it's gone, the place is simply empty).
    public var leaving: Bool?
}

/// Today's group in the day's plan: seats it took, and for the report how full the fleet would have been without it.
public struct ContractPlan: Codable, Equatable, Sendable {
    public var job: Int
    public var held: Int
    public var load: Double
    public var lost: Int
}

/// The region's contracts (`S.ctr`).
public struct ContractState: Codable, Equatable, Sendable {
    /// The day the next offer may come.
    public var next: Int?
    public var offer: ContractOffer?
    public var booked: [ContractJob] = []
    /// Jobs delivered in full (any owner) and failed.
    public var ok = 0, fail = 0
    /// Index into the cast of the owner who calls now, the trust (−9 … 5), and jobs done in full with them.
    public var who = 0, rel = 0, okWho = 0
    /// The current owner has introduced themselves.
    public var met = false
    /// Preferred operator now, and ever.
    public var pref = false, prefEver = false
    public var gone: [ContractOwner] = []
    /// The first offer's scene has been shown in this region.
    public var scene = false
    public var depart: ContractDepart?
    /// v126 (optional: older saves): jobs taken here, late planes, Hezarfen has said what a delay is, and seats kept today.
    public var taken: Int?
    public var delays: Int?
    public var delayIntroShown: Bool?
    public var wait: ContractWait?
    /// v126.1: jobs done in full per owner (raw value): the dots and "n/3" only count the owner you're dealing with.
    /// Older saves have none: `okWho` belonged to the owner calling now.
    public var okByOwner: [String: Int]?

    public init() {}

    /// v126.1: jobs done in full with this owner (`ctrOkWith`).
    public func ok(with w: ContractOwner, current: ContractOwner?) -> Int {
        if let m = okByOwner { return m[w.rawValue] ?? 0 }
        return w == current ? okWho : 0
    }
}

/// Day 1 is a Monday: 0 Monday … 5 Saturday, 6 Sunday.
public func weekday(_ d: Int) -> Int { ((d - 1) % 7 + 7) % 7 }

extension GameState {
    /// The region's contract numbers, if it has contracts.
    public var contractConfig: ContractConfig? { region.contracts }
    public var contracts: ContractState { local.contracts ?? ContractState() }
    /// The owner who calls now.
    public var contractOwner: ContractOwner? {
        guard let k = contractConfig else { return nil }
        return k.cast[contracts.who % k.cast.count]
    }
    /// Your group flying today, if any.
    public var contractToday: ContractJob? {
        guard contractConfig != nil else { return nil }
        return contracts.booked.first { $0.mine && $0.active(on: day) }
    }
    /// Nobody flies the group today: a red flag, or fog under Bristol's guarantee (`ctrOff`).
    public func contractOff(_ k: ContractJob) -> Bool {
        guard let w = local.weather else { return false }
        return w.flag == .red || (k.fogP != nil && w.fog != nil)
    }
    /// Seats today's group takes out of `cap`: it is seated first (`ctrHeld`).
    public func contractHeld(capacity cap: Int) -> Int {
        guard let k = contractToday, !contractOff(k) else { return 0 }
        return min(k.n, cap)
    }
    /// Seats in the fleet, every balloon.
    public var fleetSeats: Int { local.insideBalloons.reduce(0) { $0 + $1.size.capacity } } // v127: balloons that can fly
    /// The rival a group goes to: the most popular one still flying.
    public var contractRival: Rival? {
        var best: Rival?
        for r in local.rivals where r.alive && r.rep > (best?.rep ?? -.infinity) { best = r }
        return best
    }
    /// What a negotiation asks: a bit more, but no more than the market (and your own ticket) (`ctrNegPrice`).
    public func negotiatedPrice(_ o: ContractOffer) -> Int {
        guard let k = contractConfig else { return o.price }
        return max(o.price, min(jsRound(Double(o.price) * (1 + k.negUp) / 5) * 5, o.top))
    }
    /// The job whose vehicle should pull in now: one of its days, not arrived yet (v126.1: `ctrDue`).
    public var contractDue: ContractJob? {
        guard contractConfig != nil else { return nil }
        return contracts.booked.first { $0.mine && $0.active(on: day) && !$0.hasArrived }
    }
    /// v126.1: your jobs whose vehicle stands at the place now: arrived, and not over yet (even when moved to tomorrow).
    public var contractParked: [ContractJob] {
        guard contractConfig != nil else { return [] }
        return contracts.booked.filter { $0.mine && $0.hasArrived && $0.lastDay >= day }
    }
    /// v126: today's late plane still waiting for your answer (`ctrDelayJob`).
    public var contractDelayPending: ContractJob? {
        guard contractConfig?.delay != nil else { return nil }
        return contracts.booked.first { $0.mine && $0.delay?.choice == nil && $0.delay?.day == day && $0.delay != nil }
    }
    /// v126: seats kept empty today for a late plane that didn't come, out of `cap` (`ctrWaitSeats`).
    public func contractWaitSeats(capacity cap: Int) -> Int {
        guard contractConfig != nil, let w = contracts.wait, w.day == day else { return 0 }
        return max(0, min(w.n, cap))
    }
    /// v126: what one empty seat kept for a late plane pays.
    public var contractWaitPay: Int { contracts.wait?.pay ?? 0 }
    /// v126.1: jobs done in full with this owner (`ctrOkWith`).
    public func contractOk(with w: ContractOwner) -> Int { contracts.ok(with: w, current: contractOwner) }
    /// v126: Albuquerque's first offer scene is short when you already had charter groups in Cappadocia.
    public var contractSceneShort: Bool {
        guard region == .abq, let c = parked[.cap]?.state.contracts else { return false }
        return (c.taken ?? 0) > 0 || c.ok > 0 || c.fail > 0
    }
}

extension Game {
    private var ctr: ContractState {
        get { state.local.contracts ?? ContractState() }
        set { state.local.contracts = newValue }
    }

    private func roundRange(_ r: ClosedRange<Double>, _ x: Double) -> Int { jsRound(r.lowerBound + x * (r.upperBound - r.lowerBound)) }

    /// An owner's words on a morning card, in the boss's bubble (`ctrSay`).
    private mutating func ctrSay(_ w: ContractOwner, _ line: ContractLine, n: Int = 0, price: Int = 0) {
        state.hezQueue.append(.contract(w, line, n: n, price: price))
    }

    /// Days that went by while you were in another region: the manager saw those groups off, nothing is owed either way.
    mutating func contractTidy() {
        guard var c = state.local.contracts else { return }
        let d = state.day
        c.booked.removeAll { $0.lastDay < d }
        if let o = c.offer, o.day <= d { c.offer = nil }
        state.local.contracts = c
    }

    /// Each morning, after the day's weather (`ctrMorning`): a red flag moves a one-day group or skips a day of a block,
    /// Bristol's fog follows the forecast given with the offer, an unanswered offer lapses to a rival, and maybe a new
    /// offer comes.
    public mutating func contractMorning() {
        guard let K = state.contractConfig else { return }
        if state.local.contracts == nil { state.local.contracts = ContractState() }
        contractTidy()
        let d = state.day
        if let o = ctr.offer, o.made < d { declineContract() }
        guard var w = state.weather else { return }
        let red = w.flag == .red
        // the forecast decides today's fog for a booked weekend day (yours or a rival's)
        if let fk = ctr.booked.first(where: { $0.fogP != nil && $0.active(on: d) }), !red, let fp = fk.fogP {
            let p = d - fk.day < fp.count ? fp[d - fk.day] : 0
            w.fog = rng.chance(p) ? Fog(top: Double(jsRound(rng.range(90, 150)))) : nil
            state.weather = w
        }
        var c = ctr
        if red {
            for i in c.booked.indices where c.booked[i].active(on: d) {
                var k = c.booked[i]
                if !K.redMove || k.len > 1 {
                    if k.mine { ctrSay(k.owner, .redSkip, n: k.n, price: k.price) }
                    continue
                }
                k.moves += 1
                if k.moves > 2 {
                    // three red mornings in a row: the tour goes home, nobody's fault
                    if k.mine { ctrSay(k.owner, .redCancel) }
                    k.n = -1
                } else {
                    if k.moves == 1 { k.price = jsRound(Double(k.price) * (1 - K.redCut)) }
                    k.day += 1
                    if k.mine { ctrSay(k.owner, .red, price: k.price) }
                }
                c.booked[i] = k
            }
            c.booked.removeAll { $0.n < 0 }
        }
        state.local.contracts = c
        if K.delay != nil { contractDelayMorning() } // v126: the charter plane that was said to be late may be
        c = ctr
        if let mine = state.contractToday, !red, mine.delay == nil {
            if mine.fogP != nil && w.fog != nil { ctrSay(mine.owner, .fog) }
            else if d == mine.day { ctrSay(mine.owner, mine.warned == true ? .onTime : .today, n: mine.n, price: mine.price) }
        }
        guard state.local.chapter >= K.minChapter else { return }
        if c.next == nil { c.next = max(d + K.firstWait, K.firstDay); state.local.contracts = c }
        guard c.offer == nil, !c.booked.contains(where: \.mine), d >= (c.next ?? d), state.fleetSeats >= K.minSeats,
              let owner = state.contractOwner else { return }
        // v126: not on a crowded morning (a morning event, a chapter, several cards already): the next quiet one
        if K.quiet && (contractEventDue || state.chapterNews != nil || state.hezQueue.count > 2 || state.transferAsk != nil || state.mergeNews != nil) { return }
        let seats = state.fleetSeats
        let n = max(12, jsRound(Double(seats) * rng.range(K.share.lowerBound, K.share.upperBound) / 2) * 2)
        let riv = state.rivals.filter(\.alive)
        let ref = riv.isEmpty ? Double(state.price) : (Double(state.price) + Double(riv.reduce(0) { $0 + $1.price }) / Double(riv.count)) / 2
        // v125.3: a tour operator buys in bulk: below the market, never above your own ticket
        let cap5 = Int((min(ref, Double(state.price)) / 5).rounded(.down)) * 5
        let price = min(cap5, jsRound(ref * rng.range(K.price.lowerBound, K.price.upperBound) * (c.pref ? K.prefPrice : 1) / 5) * 5)
        var day = d + roundRange(K.lead, rng.unit())
        if K.weekend { while weekday(day) != 5 { day += 1 } }
        let len = roundRange(K.len, rng.unit())
        var o = ContractOffer(owner: owner, n: n, price: price, day: day, len: len, fogP: nil, made: d, seen: nil, first: !c.scene, top: cap5, negotiated: false)
        if K.fogGuarantee {
            o.fogP = (0..<len).map { _ in Double(jsRound(rng.range(K.fogP.lowerBound, K.fogP.upperBound) * 20)) / 20 }
        }
        c.offer = o
        state.local.contracts = c
    }

    /// v126: a morning event is due this morning (the same test as `scheduleEvent`, which runs when the day starts).
    private var contractEventDue: Bool {
        state.day >= 12 && state.unlocked.contains(.crew) && state.winter == nil && state.day >= (state.nextEvent ?? 12)
    }

    private mutating func contractNextGap() {
        guard let K = state.contractConfig else { return }
        var c = ctr
        let g = c.pref ? K.prefGap : K.gap
        c.next = state.day + jsRound(rng.range(g.lowerBound, g.upperBound))
        ctr = c
    }

    private mutating func contractRel(_ d: Int) {
        var c = ctr
        c.rel = clamp(c.rel + d, -9, 5)
        ctr = c
    }

    /// The group goes to the most popular rival (`ctrToRival`).
    private mutating func contractToRival(owner: ContractOwner, n: Int, price: Int, day: Int, len: Int, fogP: [Double]?) {
        guard let r = state.contractRival else { return }
        var c = ctr
        c.booked.append(ContractJob(id: state.nextID, owner: owner, n: n, price: price, day: day, len: len, fogP: fogP, rival: r.name))
        state.nextID += 1
        ctr = c
    }

    /// The card has been shown today.
    public mutating func markContractOfferSeen() {
        guard var c = state.local.contracts, c.offer != nil else { return }
        c.offer?.seen = state.day
        state.local.contracts = c
    }

    /// The first offer's scene has been played in this region.
    public mutating func markContractScene() {
        var c = ctr
        c.scene = true
        ctr = c
    }

    /// Takes the offer: the group is booked (`ctrAccept`).
    public mutating func acceptContract() {
        var c = ctr
        guard let o = c.offer else { return }
        c.taken = (c.taken ?? 0) + 1 // v126: the how-manyth job here
        var k = ContractJob(id: state.nextID, owner: o.owner, n: o.n, price: o.price, day: o.day, len: o.len, fogP: o.fogP)
        k.nth = c.taken
        c.booked.append(k)
        state.nextID += 1
        c.offer = nil
        c.met = true
        ctr = c
        contractNextGap()
    }

    /// Asks more per head: a higher price (true; then accept), or the company walks to a rival (false) (`ctrNegotiate`).
    public mutating func negotiateContract() -> Bool? {
        guard let K = state.contractConfig, var o = ctr.offer, !o.negotiated else { return nil }
        if rng.chance(ctr.pref ? K.prefWalk : K.negWalk) {
            contractRel(-1)
            contractToRival(owner: o.owner, n: o.n, price: o.price, day: o.day, len: o.len, fogP: o.fogP)
            var c = ctr
            c.offer = nil
            c.met = true
            ctr = c
            contractNextGap()
            contractBreakCheck()
            return false
        }
        o.price = state.negotiatedPrice(o)
        o.negotiated = true
        var c = ctr
        c.offer = o
        ctr = c
        return true
    }

    /// Says no (or leaves the offer unanswered till the next morning): the group goes to a rival (`ctrDecline`).
    public mutating func declineContract() {
        guard let o = ctr.offer else { return }
        contractRel(-1)
        contractToRival(owner: o.owner, n: o.n, price: o.price, day: o.day, len: o.len, fogP: o.fogP)
        var c = ctr
        c.offer = nil
        c.met = true
        ctr = c
        contractNextGap()
        contractBreakCheck()
    }

    /// Too many no's or failures: the owner stops calling; after a while the next owner of the cast comes
    /// (`ctrBreakCheck`).
    mutating func contractBreakCheck() {
        guard let K = state.contractConfig, let w = state.contractOwner else { return }
        var c = ctr
        if c.pref && c.rel < 1 {
            c.pref = false
            ctr = c
            ctrSay(w, .lostPref)
        }
        guard c.rel <= K.breakAt else { return }
        ctrSay(w, .bye)
        var by = c.okByOwner ?? [w.rawValue: c.okWho]
        by[w.rawValue] = 0
        c.okByOwner = by
        c.gone.append(w)
        c.who = (c.who + 1) % K.cast.count
        c.rel = 0
        c.okWho = 0
        c.pref = false
        c.met = false
        c.next = state.day + K.cool
        ctr = c
    }

    /// The vehicle of a running job pulled in at the off-map place (the town shows it arriving the first time you look);
    /// v126.1: once, it then stays until the job is over.
    public mutating func markContractArrived() {
        guard var c = state.local.contracts, let i = c.booked.firstIndex(where: { $0.mine && $0.active(on: state.day) && !$0.hasArrived }) else { return }
        c.booked[i].arrived = state.day
        c.depart = nil
        state.local.contracts = c
    }

    /// v126.1: a finished job's vehicle starts to leave (it leaves once; after a restart the place is empty).
    public mutating func markContractLeaving() {
        guard var c = state.local.contracts, c.depart != nil, c.depart?.leaving != true else { return }
        c.depart?.leaving = true
        state.local.contracts = c
    }

    // MARK: v126: the late charter plane

    /// The morning a warned charter plane's job starts: it is late with `lateP`; how likely it still makes the morning,
    /// and whether it will (`ctrDelayMorning`). The first time, Hezarfen says what this is.
    mutating func contractDelayMorning() {
        guard let D = state.contractConfig?.delay, var c = state.local.contracts, let w = state.weather, w.flag != .red,
              let i = c.booked.firstIndex(where: { $0.mine && $0.active(on: state.day) }) else { return }
        var k = c.booked[i]
        guard k.warned == true, k.delay == nil, state.day == k.day else { return }
        guard rng.chance(D.lateP) else { return }
        let q = Double(jsRound(rng.range(D.land.lowerBound, D.land.upperBound) * 10)) / 10
        k.delay = ContractDelay(day: state.day, chance: q, lands: rng.chance(q), choice: nil)
        c.booked[i] = k
        c.delays = (c.delays ?? 0) + 1
        if c.delayIntroShown != true {
            c.delayIntroShown = true
            state.hezQueue.append(.contractDelayIntro)
        }
        state.local.contracts = c
    }

    /// Your answer to a late plane (`ctrDelayChoose`): keep the seats (it lands and the group flies, or it doesn't: the
    /// seats fly empty, the agency pays, the group moves a day) or sell them (the group moves a day; if the plane made
    /// it after all, trust −1).
    @discardableResult
    public mutating func chooseContractDelay(_ ch: DelayChoice) -> DelayOutcome? {
        guard let K = state.contractConfig, let D = K.delay, let pk = state.contractDelayPending, var c = state.local.contracts,
              let i = c.booked.firstIndex(where: { $0.id == pk.id }), var dl = c.booked[i].delay else { return nil }
        var k = c.booked[i]
        dl.choice = ch
        k.delay = dl
        if ch == .hold && dl.lands {
            c.booked[i] = k
            state.local.contracts = c
            return .landed
        }
        k.day += 1
        if ch == .open && dl.lands && k.arrived == nil { k.arrived = state.day } // it landed after all: it stands there
        c.booked[i] = k
        if ch == .hold {
            c.wait = ContractWait(day: state.day, n: k.n, pay: jsRound(Double(k.price) * D.waitPay), owner: k.owner)
            state.local.contracts = c
            return .noShow
        }
        state.local.contracts = c
        if dl.lands {
            contractRel(-1)
            contractBreakCheck()
            return .stranded
        }
        return .openOk
    }

    /// A finished job's vehicle has left: the place is empty again.
    public mutating func clearContractDepart() {
        guard var c = state.local.contracts, c.depart != nil else { return }
        c.depart = nil
        state.local.contracts = c
    }

    /// Today's group in the plan, given the day's seats (`launch`).
    func contractPlan(capacity cap: Int, marketPax: Int) -> ContractPlan? {
        guard let k = state.contractToday else { return nil }
        let held = state.contractHeld(capacity: cap)
        let free = cap > 0 ? market(price: state.price, capacity: cap).pax[0] : 0
        return ContractPlan(job: k.id, held: held, load: cap > 0 ? Double(free) / Double(cap) : 1, lost: max(0, free - marketPax))
    }

    /// The evening of a contract day (`ctrSettle`): what flew, what it paid, what it cost, and the rival's share. A
    /// block (Luxor) or a weekend (Bristol) is judged on its last day. Rivals' groups go into the day's plan.
    mutating func contractSettle(plan: inout DayPlan, ledger lg: inout Ledger, events ev: inout [DayEvent], rivalEvents rev: inout [DayEvent], paxTotal: Int) {
        guard let K = state.contractConfig, var c = state.local.contracts, let w = state.weather else { return }
        let d = state.day, red = w.flag == .red
        // v126: seats kept for a late plane that didn't make it flew empty; the agency pays for them
        if let W = c.wait, W.day == d {
            let n = min(W.n, plan.contractWait ?? 0)
            c.wait = nil
            state.local.contracts = c
            if n > 0 {
                lg.contractWait = n * W.pay
                ev.append(.contractDelayNoShow(owner: W.owner, seats: n, amount: n * W.pay))
            }
        }
        if let mi = c.booked.firstIndex(where: { $0.mine && $0.active(on: d) }) {
            var mine = c.booked[mi]
            let owner = mine.owner, multi = mine.len > 1, dayN = d - mine.day + 1
            if state.contractOff(mine) {
                if mine.fogP != nil && w.fog != nil && !red {
                    let v = jsRound(Double(mine.n * mine.price) * K.voucher)
                    lg.contractVoucher = v
                    mine.fogged += 1
                    ev.append(.contractFog(company: owner.company, n: mine.n, voucher: v))
                } else {
                    ev.append(.contractRed(company: owner.company))
                }
            } else {
                let got = min(mine.n, plan.contract?.held ?? 0, paxTotal), short = mine.n - got
                lg.tickets -= got * state.price
                lg.contract = got * mine.price
                lg.contractN = got
                let perSeat = jsRound(Double(mine.price) * K.pen), pen = short * perSeat
                if pen > 0 { lg.contractPenalty = pen }
                mine.got += got
                mine.short += short
                mine.flown += 1
                ev.append(.contractFlown(company: owner.company, dayN: multi ? dayN : 0, len: multi ? mine.len : 0, n: got, price: mine.price, total: got * mine.price))
                if short > 0 {
                    ev.append(.contractShort(short: short, perSeat: perSeat, total: pen))
                    rep(.contract, -0.02)
                    c.booked[mi] = mine
                    state.local.contracts = c
                    contractToRival(owner: owner, n: short, price: mine.price, day: d, len: 1, fogP: nil)
                    c = ctr
                }
            }
            c.booked[mi] = mine
            state.local.contracts = c
            if d == mine.lastDay { // the job is judged as a whole
                c.depart = ContractDepart(owner: owner, n: mine.n, from: d + 1) // it leaves the next time you look
                state.local.contracts = c
                if mine.flown == 0 {
                    ev.append(.contractWeather(company: owner.company))
                } else if mine.short == 0 {
                    // v126.1: the job's own owner's count; trust and the title only with the owner calling now
                    let cur = owner == state.contractOwner
                    var by = c.okByOwner ?? (state.contractOwner.map { [$0.rawValue: c.okWho] } ?? [:])
                    let nOk = (by[owner.rawValue] ?? 0) + 1
                    by[owner.rawValue] = nOk
                    c.okByOwner = by
                    if cur { c.okWho = nOk }
                    c.ok += 1
                    if cur { c.rel = clamp(c.rel + 1, -9, 5) }
                    if cur && !c.pref && nOk >= K.prefNeed && c.rel >= 2 {
                        c.pref = true
                        c.prefEver = true
                        state.local.contracts = c
                        ctrSay(owner, .pref)
                        addPaper(.preferredOperator(company: owner.company, kind: K.kind))
                    } else {
                        state.local.contracts = c
                        ctrSay(owner, .thanks)
                    }
                    if cur && !c.pref && nOk < K.prefNeed { ev.append(.contractProgress(owner: owner, ok: nOk, need: K.prefNeed)) }
                } else {
                    c.fail += 1
                    c.rel = clamp(c.rel + (Double(mine.got) >= Double(mine.got + mine.short) * 0.75 ? -1 : -2), -9, 5)
                    state.local.contracts = c
                    ev.append(.contractTrustDown(owner: owner, short: mine.short))
                    ctrSay(owner, .fail)
                    contractBreakCheck()
                }
                c = ctr
            }
        }
        // The rivals' groups: today's passengers (over its seats if need be), a bit of popularity, and on the first day
        // the group's money buys it balloons at once; that's what makes saying no felt.
        for ki in c.booked.indices where !c.booked[ki].mine && c.booked[ki].active(on: d) {
            var k = c.booked[ki]
            if red || (k.fogP != nil && w.fog != nil) { continue }
            guard let ri = state.rivals.firstIndex(where: { $0.alive && $0.name == k.rival })
                    ?? state.contractRival.flatMap({ r in state.rivals.firstIndex { $0.id == r.id && $0.alive } }) else { continue }
            while plan.rivalPax.count <= ri { plan.rivalPax.append(0) }
            while plan.rivalCap.count <= ri { plan.rivalCap.append(0) }
            plan.rivalPax[ri] += k.n
            plan.rivalCap[ri] = max(plan.rivalCap[ri], plan.rivalPax[ri])
            if k.paid { continue }
            k.paid = true
            c.booked[ki] = k
            var r = state.rivals[ri]
            r.rep = min(1.4, r.rep + K.rivalRep)
            r.cash += Double(k.n * k.len * max(0, k.price - r.price))
            let nb: BalloonSize = r.style == .safe ? .L : .M
            let maxB = (r.style == .safe ? 25 : r.style == .mid ? 18 : 12) + 5, tot = k.n * k.len
            var grow = 0
            let want = max(tot >= K.rivalGrow ? 1 : 0, tot / (K.rivalGrow * 2))
            while grow < want && r.balloons.count < maxB {
                r.balloons.append(nb)
                r.damagedUntil.append(0)
                grow += 1
            }
            state.rivals[ri] = r
            addPaper(.rivalGroup(rival: r.name, company: k.owner.company, n: k.n, len: k.len, balloons: grow, kind: K.kind))
            rev.append(.rivalFlewGroup(rival: r.name, company: k.owner.company, n: k.n, len: k.len, balloons: grow))
        }
        c.booked.removeAll { $0.lastDay == d }
        // v126: the evening before a charter group's first morning: maybe "the plane may be late" (never in the first jobs)
        if let D = K.delay {
            for i in c.booked.indices where c.booked[i].mine && c.booked[i].day == d + 1 && c.booked[i].warnRolled != true {
                c.booked[i].warnRolled = true
                if (c.booked[i].nth ?? 0) > D.after && rng.chance(D.warnP) {
                    c.booked[i].warned = true
                    ev.append(.contractDelayWarning(owner: c.booked[i].owner))
                }
            }
        }
        state.local.contracts = c
    }
}
