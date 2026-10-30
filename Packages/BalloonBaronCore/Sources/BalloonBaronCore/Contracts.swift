import Foundation

// v125–v125.3: corporate contracts (`CTR` in the prototype). Now and then a morning a local company's owner offers a
// group at a price below the market: tour coaches in Albuquerque (one day), Nile cruise ships in Luxor (a block of
// mornings), London weekend trains in Bristol (Saturday and Sunday, with a fog guarantee). Each region has its own cast
// of three owners; saying no, or not delivering, sends the group to the most popular rival, who grows with it.

/// What stands at the off-map place and brings the group: coaches, a cruise ship or a steam train.
public enum ContractKind: String, Codable, Sendable {
    case bus, ship, train
}

/// The owners of the contract companies, three per region (`CTR_CAST_*`). Their names, titles and lines live in the
/// string catalog under `ctr.<rawValue>.*`; the company names are proper names, like the rivals'.
public enum ContractOwner: String, Codable, CaseIterable, Sendable {
    case rosa, hank, linda
    case farouk, dalia, hamza
    case nigel, priya, fiona

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
        }
    }
}

/// What an owner says on a morning card (`ctrSay`). Text: `ctr.<owner>.<rawValue>`.
public enum ContractLine: String, Codable, Sendable {
    case today, thanks, pref, fail, lostPref, red, redSkip, redCancel, fog, bye
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

    public static func of(_ r: RegionID) -> ContractConfig? {
        switch r {
        case .cap: return nil
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
    /// The day its vehicle pulled in at the off-map place (it does when you first look on its first day).
    public var arrived: Int?

    public var lastDay: Int { day + len - 1 }
    public func active(on d: Int) -> Bool { d >= day && d <= lastDay }
    public var mine: Bool { rival == nil }
}

/// A finished job's vehicle waits at the off-map place until you look, then leaves (from `from`).
public struct ContractDepart: Codable, Equatable, Sendable {
    public var owner: ContractOwner
    public var n: Int
    public var from: Int
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

    public init() {}
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
    public var fleetSeats: Int { local.balloons.reduce(0) { $0 + $1.size.capacity } }
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
    /// Vehicles at the off-map place now: your running jobs' (arrived), and a finished job's waiting to leave.
    public var contractDue: ContractJob? {
        guard contractConfig != nil else { return nil }
        return contracts.booked.first { $0.mine && $0.day == day && $0.arrived != day }
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
        if let mine = state.contractToday, !red {
            if mine.fogP != nil && w.fog != nil { ctrSay(mine.owner, .fog) } else if d == mine.day { ctrSay(mine.owner, .today, n: mine.n, price: mine.price) }
        }
        guard state.local.chapter >= K.minChapter else { return }
        if c.next == nil { c.next = d + K.firstWait; state.local.contracts = c }
        guard c.offer == nil, !c.booked.contains(where: \.mine), d >= (c.next ?? d), state.fleetSeats >= K.minSeats,
              let owner = state.contractOwner else { return }
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
        c.booked.append(ContractJob(id: state.nextID, owner: o.owner, n: o.n, price: o.price, day: o.day, len: o.len, fogP: o.fogP))
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
        c.gone.append(w)
        c.who = (c.who + 1) % K.cast.count
        c.rel = 0
        c.okWho = 0
        c.pref = false
        c.met = false
        c.next = state.day + K.cool
        ctr = c
    }

    /// The vehicle of today's job pulled in at the off-map place (the town shows it arriving the first time you look).
    public mutating func markContractArrived() {
        guard var c = state.local.contracts, let i = c.booked.firstIndex(where: { $0.mine && $0.day == state.day && $0.arrived != state.day }) else { return }
        c.booked[i].arrived = state.day
        c.depart = nil
        state.local.contracts = c
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
                    c.ok += 1
                    c.okWho += 1
                    c.rel = clamp(c.rel + 1, -9, 5)
                    if !c.pref && c.okWho >= K.prefNeed && c.rel >= 2 {
                        c.pref = true
                        c.prefEver = true
                        state.local.contracts = c
                        ctrSay(owner, .pref)
                        addPaper(.preferredOperator(company: owner.company, kind: K.kind))
                    } else {
                        state.local.contracts = c
                        ctrSay(owner, .thanks)
                    }
                    if c.okWho < K.prefNeed { ev.append(.contractProgress(owner: owner, ok: c.okWho, need: K.prefNeed)) }
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
        state.local.contracts = c
    }
}
