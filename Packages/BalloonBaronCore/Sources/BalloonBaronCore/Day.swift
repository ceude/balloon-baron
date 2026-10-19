import Foundation

extension Game {
    /// Locks in today's passengers. Returns how many ride with you if you fly the flagship
    /// yourself; then run the flight scene and call `finishDay(flight:)` with its result.
    /// Returns nil when there is no self flight; call `finishDay(flight: nil)` straight away.
    @discardableResult
    public mutating func launch(skip: Bool = false) -> Int? {
        let fl = skip ? [] : state.flyingToday
        let cap = fl.reduce(0) { $0 + $1.size.capacity }
        let m = market(price: state.price, capacity: cap)
        var plan = DayPlan(skipped: skip, flying: fl.map(\.id), pax: [:], rivalPax: Array(m.pax.dropFirst()),
                           rivalCap: Array(m.caps.dropFirst()), referrals: skip ? 0 : m.referrals)
        var left = m.pax[0]
        let flagship = state.flagship
        for b in fl.sorted(by: { ($0.id == flagship ? 1 : 0) > ($1.id == flagship ? 1 : 0) }) {
            let n = min(left, b.size.capacity)
            plan.pax[b.id] = n
            left -= n
        }
        state.plan = plan
        if let fb = state.balloon(flagship), state.isSelf(fb), plan.flying.contains(fb.id) { return plan.pax[fb.id] ?? 0 }
        return nil
    }

    // MARK: Day end

    public mutating func finishDay(flight: FlightResult?) -> DayReport {
        guard let plan = state.plan, let weather = state.weather else { preconditionFailure("finishDay before launch") }
        let red = weather.flag == .red
        var ev: [DayEvent] = [], rev: [DayEvent] = []
        var lg = Ledger()
        var accidents: [String] = [], ads: [Sponsor] = []
        var paxTotal = 0
        let cancelled = flight?.landing == .cancel
        let flyingIDs = plan.flying.filter { state.balloon($0) != nil }

        for id in flyingIDs {
            guard let i = state.balloons.firstIndex(where: { $0.id == id }) else { continue }
            let b = state.balloons[i], z = b.size, pax = plan.pax[id] ?? 0, isSelf = state.isSelf(b)
            paxTotal += pax
            if isSelf && cancelled {
                paxTotal -= pax
                lg.cancellations += pax * Rules.cancelCompensation
                state.rep -= 0.03
                ev.append(.cancelled(balloon: b.name, pax: pax, compensation: Rules.cancelCompensation))
                continue
            }
            lg.tickets += pax * state.price
            lg.fuel += z.fuel
            if let sp = b.ad {
                lg.ads += sp.pay(for: z)
                lg.adRepLoss += sp.repLoss
                state.rep -= sp.repLoss
                ads.append(sp)
            }
            let q = premium(z, chance: accidentChance(b))
            if state.insureHull { lg.insurance += q.hull }
            if state.insurePax { lg.insurance += q.pax }

            var severity = 0.0
            if isSelf, let f = flight {
                state.lastSelfFly = state.day
                if f.missionDone, let m = f.mission {
                    lg.mission += m.reward
                    lg.missionDone = m
                    state.rep += 0.02
                    ev.append(.missionDone(m, reward: m.reward))
                } else if let m = f.mission {
                    ev.append(.missionFailed(m))
                }
                switch f.landing {
                case .perfect:
                    lg.tips += pax * 15
                    state.rep += 0.03
                    ev.append(.perfectLanding(balloon: b.name, tips: pax * 15))
                case .good:
                    lg.tips += pax * 6
                    state.rep += state.stars > 4.5 ? 0 : 0.01
                    ev.append(.goodLanding(balloon: b.name))
                case .far:
                    state.rep -= state.stars > 4.5 ? 0.04 : 0.02
                    ev.append(.farLanding(balloon: b.name, meters: jsRound(f.distance)))
                case .hard: severity = 0.3
                case .crash: severity = 0.8
                case .cancel: break
                }
            } else if rng.chance(accidentChance(b)) {
                severity = rng.range(0.2, 1)
            } else {
                state.rep += 0.004
            }

            if severity > 0 {
                let repair = jsRound(Double(z.cost) * 0.35 * severity)
                let comp = jsRound(Double(pax) * 2500 * severity)
                let days = 1 + Int((4 * severity).rounded(.up))
                let hullPaid = state.insureHull && !red, paxPaid = state.insurePax && !red
                lg.repairs += repair
                lg.compensation += comp
                if hullPaid { lg.insurancePaid += repair }
                if paxPaid { lg.insurancePaid += comp }
                state.balloons[i].damagedUntil = state.day + days
                state.rep -= 0.08 + 0.15 * severity
                if !isSelf { accidents.append(b.name) }
                let who: DayEvent.Pilot = isSelf ? .you : state.pilot(of: b).map { .named($0.name) } ?? .unknown
                let cover: DayEvent.Cover = hullPaid && paxPaid ? .all : hullPaid ? .hullOnly : paxPaid ? .paxOnly : .none
                ev.append(.accident(balloon: b.name, pilot: who, severe: severity > 0.6, days: days, repair: repair, compensation: comp, cover: cover))
            }
        }

        if red && !flyingIDs.isEmpty {
            if rng.chance(Rules.redCatch) {
                lg.fines += Rules.redFine
                state.strikes += 1
                ev.append(.redCaught(strikes: state.strikes))
                if state.strikes >= 3 {
                    state.banUntil = state.day + 3
                    state.strikes = 0
                    ev.append(.redBan)
                }
            } else {
                ev.append(.redUnseen)
            }
        }

        lg.wages = state.pilots.reduce(0) { $0 + $1.wage }
        for id in flyingIDs {
            guard let i = state.balloons.firstIndex(where: { $0.id == id }) else { continue }
            let isSelf = state.isSelf(state.balloons[i])
            if cancelled && isSelf { continue }
            state.balloons[i].flights += 1
            if !isSelf, let pid = state.balloons[i].pilot, let pi = state.pilots.firstIndex(where: { $0.id == pid }) {
                var p = state.pilots[pi]
                p.xp += 1
                if let need = p.level.xpToNext, p.xp >= need, let up = PilotLevel(rawValue: p.level.rawValue + 1) {
                    p.level = up
                    p.customWage = jsRound(Double(up.wage) * (p.fromSchool ? Rules.schoolWageFactor : 1))
                    ev.append(.pilotPromoted(name: p.name, level: up, wage: p.wage))
                }
                state.pilots[pi] = p
            }
            if state.balloons[i].condition <= 0 { ev.append(.envelopeWorn(balloon: state.balloons[i].name)) }
        }
        lg.upkeep = state.balloons.reduce(0) { $0 + $1.size.upkeep }
        for h in state.activeHotels {
            if state.ownHotels.contains(h) {
                lg.hotelIncome += state.hotelIncome(h)
                state.rep = min(1.4, state.rep + h.repPerDay * 1.5)
            } else {
                lg.hotelFees += h.dailyFee
                state.rep = min(1.4, state.rep + h.repPerDay)
            }
        }
        for k in state.loans.indices {
            lg.loans += state.loans[k].installment
            state.loans[k].daysLeft -= 1
        }
        state.loans.removeAll { $0.daysLeft <= 0 }

        state.cash += lg.net
        state.rep = clamp(lerp(state.rep, 1, 0.01), Rules.repRange.lowerBound, Rules.repRange.upperBound)
        if state.stars > 4.5 { state.rep -= 0.006 }
        state.rep += Double(flyingIDs.compactMap(state.balloon).filter { $0.size == .XL }.count) * Rules.xlRepPerFlight
        if state.licenseDaysLeft == 0 { ev.append(.licenseExpiring) }

        simulateRivals(plan: plan, weather: weather, events: &rev)

        let rivalPax = plan.rivalPax.reduce(0, +)
        let share = paxTotal + rivalPax > 0 ? Double(paxTotal) / Double(paxTotal + rivalPax) : 0
        if state.day >= 20 && share > 0.6 && state.rivals.contains(where: \.alive) {
            state.monopolyDays += 1
        } else {
            state.monopolyDays = max(0, state.monopolyDays - 1)
        }
        if state.monopolyDays >= 3 { queueTip(.antitrust) }
        if state.monopolyDays >= 5 && rng.chance(0.25) && state.cash > 0 {
            let fine = max(5000, jsRound(Double(state.cash) * 0.08 / 100) * 100)
            lg.antitrust = fine
            state.cash -= fine
            state.monopolyDays = 0
            ev.append(.antitrustFine(sharePercent: jsRound(share * 100), fine: fine))
        }

        if state.cash < Rules.seizeBelow {
            let sellable = state.balloons.filter { $0.id != state.flagship }.sorted { $0.size.cost > $1.size.cost }
            if let take = sellable.first ?? state.balloons.first {
                let v = take.size.cost / 2
                state.cash += v
                lg.seizure = v
                state.balloons.removeAll { $0.id == take.id }
                ev.append(.seized(balloon: take.name, value: v))
                if take.id == state.flagship, let first = state.balloons.first { state.flagship = first.id }
            }
            if state.balloons.isEmpty { state.over = true }
        }

        let flown = flyingIDs.compactMap(state.balloon)
        let capToday = flown.reduce(0) { $0 + $1.size.capacity }
        let landedOK = flight.map { $0.missionDone && $0.landing != .hard && $0.landing != .crash } ?? false
        generateReviews(ReviewContext(xl: flown.contains { $0.size == .XL }, mission: landedOK ? flight?.mission : nil, ads: ads,
                                      landing: flight?.landing, accidents: accidents, red: red, flew: paxTotal > 0,
                                      skipped: plan.skipped, flag: weather.flag))
        for h in state.activeHotels where !state.ownHotels.contains(h) && state.stars < h.minStars - 0.3 {
            state.hotelDeals.removeAll { $0 == h }
            ev.append(.hotelLeft(h))
        }
        if state.day <= state.influencerUntil {
            state.rep = min(1.4, state.rep + 0.03)
            if rng.chance(0.6) { addReview(.influencer) }
        }
        state.repHistory.append(RepPoint(day: state.day, rep: state.rep))
        if state.repHistory.count > 120 { state.repHistory.removeFirst() }
        state.lastShare = MarketShare(me: paxTotal, rivals: plan.rivalPax, demand: state.demand ?? 0, extra: min(plan.referrals, paxTotal))
        let report = DayReport(day: state.day, flag: weather.flag, ledger: lg, events: ev, rivalEvents: rev,
                               passengers: paxTotal, capacity: capToday, skipped: plan.skipped)

        state.day += 1
        state.plan = nil
        if let w = state.winter, state.day > w.end {
            state.winter = nil
            state.nextWinter = state.day + 45
            state.hezQueue.append(.spring)
        } else if state.winter == nil && state.day >= (state.nextWinter ?? 40) && state.cash >= 50000 {
            state.winter = Winter(start: state.day, end: state.day + 7)
            state.hezQueue.append(.winterComing)
        }
        newCandidates()
        state.weather = newWeather()
        state.demand = dayDemand()
        planRivalFlights()
        unlockCheck()
        assignPilots()
        return report
    }
}
