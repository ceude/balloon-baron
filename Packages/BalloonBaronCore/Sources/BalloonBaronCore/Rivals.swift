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
            if hits > 0 { rev.append(.rivalAccidents(rival: r.name, count: hits)) }
            if red && !r.flyToday.isEmpty {
                if rng.chance(Rules.redCatch) {
                    cost += Double(Rules.redFine)
                    rev.append(.rivalRedFined(rival: r.name))
                } else {
                    rev.append(.rivalRedSneaked(rival: r.name))
                }
            }
            r.cash += income - cost
            // Owners take money out, so rivals don't hoard forever.
            let reserve = 8000 + 1500 * Double(r.balloons.count)
            if r.cash > reserve { r.cash -= (r.cash - reserve) * 0.25 }
            r.rep = clamp(lerp(r.rep, r.style == .safe ? 1.1 : r.style == .risky ? 0.9 : 1, 0.04), 0.4, 1.4)
            r.lastPax = pax
            r.lastCap = cap

            if !state.pilots.isEmpty && state.poach == nil && r.cash > 15000 && rng.chance(0.04) {
                let best = state.pilots.sorted { ($0.level, $0.xp) > ($1.level, $1.xp) }[0]
                if best.level >= .experienced || rng.chance(0.3) {
                    state.poach = PoachOffer(rivalIndex: ri, pilotID: best.id, wage: jsRound(Double(best.wage) * 1.35 / 10) * 10)
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
                r.highDays = load > 0.9 ? r.highDays + 1 : 0
                let next: BalloonSize = r.style == .safe ? .L : .M
                let maxBalloons = r.style == .safe ? 10 : r.style == .mid ? 7 : 5
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
                rev.append(.rivalBankrupt(rival: r.name, balloons: r.balloons.count, price: r.forSale!.price))
            } else if day >= 5 && (r.lowDays >= 4 || r.cash < 5000) {
                let was = r.offer != nil
                r.offer = jsRound((fleetValue * 0.6 + max(0, r.cash)) / 100) * 100
                if !was {
                    r.offerSeen = false; r.offerDeclined = false
                    rev.append(.rivalForSale(rival: r.name, price: r.offer!))
                }
            } else {
                r.offer = nil
                r.offerSeen = false; r.offerDeclined = false
            }
        }
    }

    mutating func newEntrant(replacing old: Rival) -> Rival {
        let used = Set(state.rivals.map(\.name))
        let pool = Entrant.allCases.filter { !used.contains($0.name) }
        let e = rng.pick(pool.isEmpty ? Entrant.allCases : pool)
        let taken = Set(state.rivals.filter(\.alive).map { $0.colors[0] })
        let cols = Rules.rivalColors.filter { $0[0] != state.colors[0] && !taken.contains($0[0]) }
        let c = cols.isEmpty ? Rules.rivalColors[0] : rng.pick(cols)
        var r = Rival(id: old.id, name: e.name, colors: c, style: e.style, balloons: e.balloons, price: e.price, rep: e.rep, cash: e.cash)
        r.entrant = e
        return r
    }
}
