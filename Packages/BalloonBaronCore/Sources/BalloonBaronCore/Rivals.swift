import Foundation

extension Game {
    mutating func simulateRivals(plan: DayPlan, weather: Weather, events rev: inout [DayEvent]) {
        let flag = weather.flag, red = flag == .red, day = state.day
        for ri in state.rivals.indices {
            var r = state.rivals[ri]
            defer { state.rivals[ri] = r }

            if !r.alive {
                if r.deadDay == nil { r.deadDay = day }
                let dead = day - (r.deadDay ?? day)
                if r.forSale != nil && dead > 8 {
                    r.forSale = nil
                    rev.append(.rivalFleetSold(rival: r.name))
                }
                if r.forSale == nil && dead >= 6 && rng.chance(0.3) {
                    r = newEntrant(replacing: r)
                    rev.append(.newEntrant(rival: r.name))
                    addPaper(.newEntrant(rival: r.name))
                    if let e = r.entrant { state.hezQueue.append(.entrant(e)) }
                }
                continue
            }

            let pax = ri < plan.rivalPax.count ? plan.rivalPax[ri] : 0
            let cap = ri < plan.rivalCap.count ? plan.rivalCap[ri] : 0
            let insured = r.style != .risky
            let riskMul = r.style == .safe ? 0.8 : r.style == .risky ? 1.3 : 1
            var cost = Double(r.balloons.reduce(0) { $0 + $1.upkeep + 180 } + 150)
            let income = Double(pax * r.price)
            var hits = 0, base = 0.0
            for i in r.flyToday {
                let z = r.balloons[i], p = flag.accident * riskMul * z.risk
                cost += Double(z.fuel)
                if insured && !red {
                    let q = premium(z, chance: p)
                    cost += Double(q.hull + q.pax)
                }
                base = cost
                if rng.chance(p) {
                    let sev = rng.range(0.2, 1)
                    let share = cap > 0 ? Double(pax * z.capacity) / Double(cap) : 0
                    if !(insured && !red) { cost += Double(z.cost) * 0.35 * sev + share * 2500 * sev }
                    r.damagedUntil[i] = day + 1 + Int((4 * sev).rounded(.up))
                    r.rep -= 0.1 + 0.12 * sev
                    hits += 1
                }
            }
            if hits > 0 {
                addPaper(.rivalAccident(rival: r.name, count: hits))
                rev.append(.rivalAccidents(rival: r.name, count: hits))
            }
            if red && !r.flyToday.isEmpty {
                if rng.chance(Rules.redCatch) {
                    cost += Double(Rules.redFine)
                    addPaper(.rivalRedCaught(rival: r.name, fine: Rules.redFine))
                    rev.append(.rivalRedFined(rival: r.name))
                } else {
                    rev.append(.rivalRedSneaked(rival: r.name))
                }
            }
            r.cash += income - cost
            // Owners take money out, so rivals don't hoard forever, but they save up for the next balloon.
            let next: BalloonSize = r.style == .safe ? .L : .M
            let reserve = 8000 + 1500 * Double(r.balloons.count) + Double(next.cost) * 0.6
            if r.cash > reserve && r.warChestUntil <= day { r.cash -= (r.cash - reserve) * 0.25 }
            r.rep = clamp(lerp(r.rep, r.style == .safe ? 1.1 : r.style == .risky ? 0.9 : 1, 0.04), 0.4, 1.4)
            r.lastPax = pax
            r.lastCap = cap

            // Loyal pilots don't listen; a rest room in the pilot office halves the chance.
            let poachable = state.pilots.filter { $0.trait != .loyal }
            if !poachable.isEmpty && state.poach == nil && r.cash > 15000 && rng.chance(state.level(.office) >= 2 ? 0.02 : 0.04) {
                let best = poachable.sorted { ($0.level, $0.xp) > ($1.level, $1.xp) }[0]
                if best.level >= .experienced || rng.chance(0.3) {
                    state.poach = PoachOffer(rivalIndex: ri, pilotID: best.id, wage: jsRound(Double(best.wage) * 1.35 / 10) * 10)
                    if r.name == state.region.bossCompany { bossSay(.poach) }
                    rev.append(.poachAttempt(rival: r.name, pilot: best.name))
                }
            }
            if r.cash > 20000 && rng.chance(0.03) {
                let rivalStars = Rules.stars(r.rep)
                if let h = Hotel.allCases.first(where: { h in
                    !state.hotelActive(h) && !((state.hotelLocks[h]?.until ?? 0) > day) && rivalStars >= h.minStars
                }) {
                    state.hotelLocks[h] = HotelLock(rival: r.name, until: day + 12)
                    r.rep = min(1.4, r.rep + 0.03)
                    rev.append(.rivalHotelDeal(rival: r.name, hotel: h))
                }
            }
            if !state.hotelDeals.isEmpty && r.rep > state.rep + 0.12 && rng.chance(0.015) {
                let h = rng.pick(state.hotelDeals)
                state.hotelDeals.removeAll { $0 == h }
                state.hotelLocks[h] = HotelLock(rival: r.name, until: day + 12)
                if r.name == state.region.bossCompany { bossSay(.hotel) }
                addPaper(.hotelLost(h, rival: r.name))
                rev.append(.rivalStoleHotel(rival: r.name, hotel: h))
            }
            if r.cash > 12000 && !(r.campaignUntil > day) && rng.chance(0.04) {
                r.campaignUntil = day + 3
                r.cash -= 4000
                r.rep = min(1.4, r.rep + 0.1)
                r.price = jsRound(Double(r.price) * 0.95)
                rev.append(.rivalCampaign(rival: r.name))
            }

            if cap > 0 {
                let load = Double(pax) / Double(cap)
                let perSeat = (base > 0 ? base : cost) / Double(max(1, cap))
                let floor = perSeat / 0.75 * (r.style == .safe ? 1 : r.style == .mid ? 0.9 : 0.75)
                let old = r.price
                var price = Double(r.price)
                if load < 0.6 { price *= 0.95 } else if load > 0.95 { price *= 1.04 }
                if Double(state.price) < price * 0.9 && load < 0.7 { price *= 0.94 }
                let ceiling = r.style == .risky ? 190 : r.style == .mid ? 260 : Rules.priceRange.upperBound
                let lo = jsRound(clamp(floor, 55, Double(min(220, ceiling))))
                r.price = clamp(jsRound(price), lo, ceiling)
                if abs(r.price - old) >= 8 { rev.append(.rivalPrice(rival: r.name, from: old, to: r.price)) }
                r.lowDays = load < 0.5 ? r.lowDays + 1 : 0
                r.highDays = load > 0.7 ? r.highDays + 1 : 0
                let maxBalloons = r.style == .safe ? 25 : r.style == .mid ? 18 : 12
                if r.cash > Double(next.cost) * 0.6 && r.highDays >= 3 && r.balloons.count < maxBalloons && day - r.lastBuy >= 4 {
                    r.lastBuy = day
                    r.cash -= Double(next.cost) * 0.5
                    r.balloons.append(next)
                    r.damagedUntil.append(0)
                    rev.append(.rivalNewBalloon(rival: r.name))
                }
            }

            let fleetValue = Double(r.balloons.reduce(0) { $0 + $1.cost })
            if r.cash < -10000 && day >= 5 {
                r.alive = false
                r.deadDay = day
                r.offer = nil
                r.offerSeen = false; r.offerDeclined = false; r.saleSeen = false; r.saleDeclined = false
                r.forSale = ForSale(sizes: r.balloons, price: jsRound(fleetValue * 0.45 / 100) * 100)
                addPaper(.rivalBankrupt(rival: r.name, balloons: r.balloons.count))
                if r.name == state.region.bossCompany { bossSay(.gone) }
                rev.append(.rivalBankrupt(rival: r.name, balloons: r.balloons.count, price: r.forSale!.price))
            } else if day >= 5 && (r.lowDays >= 4 || r.cash < 5000) {
                let was = r.offer != nil
                r.offer = jsRound((fleetValue * 0.6 + max(0, r.cash)) / 100) * 100
                if !was {
                    r.offerSeen = false; r.offerDeclined = false
                    if r.name == state.region.bossCompany { bossSay(.deal) }
                    rev.append(.rivalForSale(rival: r.name, price: r.offer!))
                }
            } else {
                r.offer = nil
                r.offerSeen = false; r.offerDeclined = false
            }
        }
    }

    mutating func newEntrant(replacing old: Rival) -> Rival {
        // Skip brands already flying or for sale, also inside merged names like "X & Bosphorus Balloons".
        let used = state.rivals.filter { $0.alive || $0.forSale != nil }.map(\.name).joined(separator: " ")
        let all = state.region.entrants
        let pool = all.filter { !used.contains($0.name.split(separator: " ")[0]) }
        let e = rng.pick(pool.isEmpty ? all : pool)
        let taken = Set(state.rivals.filter(\.alive).map { $0.colors[0] })
        let cols = Rules.rivalColors.filter { $0[0] != state.colors[0] && !taken.contains($0[0]) }
        let c = cols.isEmpty ? Rules.rivalColors[0] : rng.pick(cols)
        let fleet = entrantFleet(e)
        var r = Rival(id: old.id, name: e.name, colors: c, style: e.style, balloons: fleet.balloons, price: e.price, rep: e.rep, cash: fleet.cash)
        r.entrant = e
        r.warChestUntil = state.day + 20
        return r
    }

    /// A rich chain arrives with three balloons more than you; after day 50 others come with half your fleet.
    func entrantFleet(_ e: Entrant) -> (balloons: [BalloonSize], cash: Double) {
        let mine = state.balloons.count
        var n = e.balloons.count
        if e.rich { n = max(n, mine + 3) } else if state.day >= 50 { n = max(n, jsRound(Double(mine) / 2)) }
        let mix: [BalloonSize] = switch e.style {
        case .safe: [.L, .L, .M, .M, .M]
        case .mid: [.L, .M, .M, .M, .S]
        case .risky: [.M, .S, .S, .S, .M]
        }
        let balloons = n == e.balloons.count ? e.balloons : (0..<n).map { mix[$0 % mix.count] }
        let extra = Double(n - e.balloons.count)
        return (balloons, e.rich ? max(e.cash, 60000 + 9000 * Double(n)) : e.cash + 6000 * extra)
    }

    /// The two smallest rivals join forces against a player who owns the market.
    mutating func mergeRivals(share: Double, events rev: inout [DayEvent]) {
        func seats(_ r: Rival) -> Int { r.balloons.reduce(0) { $0 + $1.capacity } }
        let alive = state.rivals.indices.filter { state.rivals[$0].alive }.sorted { seats(state.rivals[$0]) < seats(state.rivals[$1]) }
        guard alive.count >= 2 else { return }
        let a = state.rivals[alive[0]], b = state.rivals[alive[1]]
        let name = "\(a.name.split(separator: " ")[0]) & \(b.name.split(separator: " ")[0]) Balloons"
        let (bi, oi) = seats(a) >= seats(b) ? (alive[0], alive[1]) : (alive[1], alive[0])
        let big = state.rivals[bi], other = state.rivals[oi]
        let cash = jsRound((max(0, a.cash) + max(0, b.cash)) * 1.3 + 40000)
        let rep = max(a.rep, b.rep)
        state.mergeNews = MergeNews(a: a.name, b: b.name, name: name, balloons: a.balloons.count + b.balloons.count, cash: cash,
                                    sharePercent: jsRound(share * 100), rep: rep, colors: big.colors + [other.colors[0]])
        var m = big
        m.name = name
        m.style = a.style == .safe || b.style == .safe ? .safe : .mid
        m.balloons = a.balloons + b.balloons
        m.damagedUntil = a.damagedUntil + b.damagedUntil
        m.cash = Double(cash)
        m.rep = rep
        m.price = jsRound(Double(a.price + b.price) / 2)
        m.lowDays = 0; m.highDays = 0
        m.offer = nil; m.offerSeen = false; m.offerDeclined = false
        m.warChestUntil = state.day + 20
        m.mergedInto = nil
        m.entrant = nil
        m.flyToday = []
        var o = other
        o.alive = false
        o.deadDay = state.day
        o.forSale = nil
        o.offer = nil
        o.mergedInto = name
        o.flyToday = []
        state.rivals[bi] = m
        state.rivals[oi] = o
        state.lastMerge = state.day
        rev.append(.rivalsMerged(a: a.name, b: b.name, name: name, balloons: m.balloons.count))
    }
}
