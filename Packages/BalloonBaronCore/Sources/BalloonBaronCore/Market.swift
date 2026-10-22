import Foundation

/// Where today's passengers come from, for the collection screen.
public enum PaxSource: Equatable, Hashable, Sendable {
    case tourists, hotel(Hotel), guide, influencer, popularity
}

public struct MarketResult: Equatable, Sendable {
    /// Index 0 is you, then each rival.
    public var pax: [Int]
    public var caps: [Int]
    /// Passengers that came through referrals (hotels, guide, influencer, popularity).
    public var referrals: Int
    /// Passengers you won on the open market.
    public var base: Int
    public var parts: [(source: PaxSource, count: Int)]

    public static func == (a: Self, b: Self) -> Bool {
        a.pax == b.pax && a.caps == b.caps && a.referrals == b.referrals && a.base == b.base
            && a.parts.map(\.source) == b.parts.map(\.source) && a.parts.map(\.count) == b.parts.map(\.count)
    }
}

public struct Competitor: Sendable {
    public var price: Double, rep: Double, cap: Int
}

public enum Market {
    /// Splits `tourists` between competitors by popularity² × price appeal, then lets the
    /// overflow from full or too-pricey companies spill to anyone with empty seats.
    public static func allocate(_ comps: [Competitor], tourists: Int) -> [Int] {
        let t = Double(tourists)
        let w = comps.map { Rules.willing($0.price) }
        let att = comps.map { c -> Double in
            c.cap > 0 ? c.rep * c.rep * (c.rep < Rules.crisisRep ? 0.35 : 1) * pow(190 / c.price, 1.5) * pow(Double(c.cap), Rules.seatWeight) : 0
        }
        let sum = att.reduce(0, +)
        guard sum > 0 else { return comps.map { _ in 0 } }
        let want = att.map { t * $0 / sum }
        var pax = comps.indices.map { min(comps[$0].cap, Int((want[$0] * w[$0]).rounded(.down))) }
        var pool = comps.indices.reduce(0.0) { acc, i in
            acc + max(0, want[i] * w[i] - Double(comps[i].cap)) + want[i] * (1 - w[i]) * 0.5
        }
        var pass = 0
        while pass < 3 && pool >= 1 {
            let sp = comps.indices.map { comps[$0].cap - pax[$0] > 0 ? att[$0] : 0 }
            let s2 = sp.reduce(0, +)
            if s2 == 0 { break }
            var next = 0.0
            for i in comps.indices where sp[i] > 0 {
                let offered = pool * sp[i] / s2
                let take = min(comps[i].cap - pax[i], Int((offered * w[i]).rounded(.down)))
                pax[i] += take
                next += max(0, offered * w[i] - Double(take))
            }
            pool = next
            pass += 1
        }
        return pax
    }
}

extension Game {
    /// Extra passengers popularity brings regardless of rivals, at today's price. It scales with
    /// your own seats so a tiny newcomer can't fill up on reputation alone.
    public func popularityBonus() -> Int {
        jsRound(Double(popularityBonusRaw()) * Rules.willing(Double(state.price)))
    }

    func popularityBonusRaw() -> Int {
        jsRound(Double(state.capacityToday) * Rules.popularitySeatShare * clamp((state.rep - 0.7) / 0.7, 0, 1))
    }

    /// Tourists looking for a flight today, whatever your price: the market plus hotel guests,
    /// guide and influencer referrals and your fans. Price only changes how many pick you.
    public func touristsToday() -> Int {
        let s = state, winter = s.winter != nil
        let hotels = s.activeHotels.reduce(0) { acc, h in
            acc + jsRound(Double(h.guests) * (s.ownHotels.contains(h) ? 1.5 : 1) * (winter ? 0.6 : 1))
        }
        return (s.demand ?? 0) + hotels + (s.day <= s.guideUntil ? 5 : 0) + (s.day <= s.influencerUntil ? 8 : 0) + popularityBonusRaw()
    }

    /// Ticket money (plus the founder premium) you'd make at `price` with today's fleet.
    public func estimatedIncome(price: Int? = nil) -> (pax: Int, seats: Int, income: Int) {
        var g = self
        if let price { g.state.price = price }
        let fl = g.state.flyingToday, cap = fl.reduce(0) { $0 + g.state.sellSeats($1) }
        let pax = g.market(price: g.state.price, capacity: cap).pax[0]
        var income = pax * g.state.price
        if let fb = fl.first(where: { g.state.isSelf($0) }) {
            income += jsRound(Double(min(pax, g.state.sellSeats(fb)) * g.state.price) * Rules.founderPremium)
        }
        return (pax, cap, income)
    }

    /// Where `price` sits on the tourists' scale: 0 = good value … 100 = far too expensive.
    /// Bands: ≥85% willing, ≥60%, ≥35%, below.
    public static func feel(price: Int) -> Int {
        let w = Rules.willing(Double(price)), cuts = [1, 0.85, 0.6, 0.35, 0]
        for i in 0..<4 where w >= cuts[i + 1] {
            return jsRound((Double(i) + (cuts[i] - w) / (cuts[i] - cuts[i + 1])) * 25)
        }
        return 100
    }

    /// Referral sources before capacity limits.
    public func referralSources() -> [(source: PaxSource, count: Int)] {
        let s = state, p = Double(s.price), winter = s.winter != nil
        var out: [(PaxSource, Int)] = s.activeHotels.map { h in
            let n = Double(h.guests) * (s.ownHotels.contains(h) ? 1.5 : 1) * (winter ? 0.6 : 1) * Rules.willing(p, center: h.priceCenter)
            return (.hotel(h), jsRound(n))
        }
        if s.day <= s.guideUntil { out.append((.guide, jsRound(5 * Rules.willing(p)))) }
        if s.day <= s.influencerUntil { out.append((.influencer, jsRound(8 * Rules.willing(p)))) }
        out.append((.popularity, popularityBonus()))
        return out.filter { $0.1 > 0 }
    }

    /// Who gets which tourists today, given your price and seats.
    public func market(price: Int, capacity: Int) -> MarketResult {
        let s = state
        var comps = [Competitor(price: Double(price), rep: s.rep, cap: capacity)]
        comps += s.rivals.map { r in
            Competitor(price: Double(r.price), rep: r.rep, cap: r.alive ? r.flyToday.reduce(0) { $0 + r.balloons[$1].capacity } : 0)
        }
        let src = referralSources()
        var parts: [(source: PaxSource, count: Int)] = []
        var room = capacity
        // Contracted sources fill your seats first, then the open market, then popularity.
        for x in src where x.source != .popularity {
            let n = min(room, x.count)
            if n > 0 { parts.append((x.source, n)); room -= n }
        }
        comps[0].cap = room
        var pax = Market.allocate(comps, tourists: s.demand ?? 0)
        let base = pax[0]
        room -= base
        for x in src where x.source == .popularity {
            let n = min(room, x.count)
            if n > 0 { parts.append((x.source, n)); room -= n }
        }
        comps[0].cap = capacity
        let add = parts.reduce(0) { $0 + $1.count }
        pax[0] += add
        return MarketResult(pax: pax, caps: comps.map(\.cap), referrals: add, base: base, parts: parts)
    }
}
