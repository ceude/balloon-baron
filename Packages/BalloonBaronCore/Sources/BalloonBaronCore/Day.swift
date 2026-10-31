import Foundation

extension Game {
    /// Locks in today's passengers. Returns how many ride with you if you fly the flagship
    /// yourself; then run the flight scene and call `finishDay(flight:)` with its result.
    /// Returns nil when there is no self flight; call `finishDay(flight: nil)` straight away.
    @discardableResult
    public mutating func launch(skip: Bool = false) -> Int? {
        let fl = skip ? [] : state.flyingToday
        let cap = fl.reduce(0) { $0 + state.sellSeats($1) }
        // v125: a contract group booked for today takes its seats first; the market gets the rest
        // v126: a late charter plane left unanswered (autopilot): the seats wait for it
        if state.contractDelayPending != nil { chooseContractDelay(.hold) }
        let held = state.contractHeld(capacity: cap)
        // v126: seats kept empty for a late plane that didn't come aren't sold either
        let wait = state.contractWaitSeats(capacity: cap - held)
        let m = market(price: state.price, capacity: cap - held - wait)
        var plan = DayPlan(skipped: skip, flying: fl.map(\.id), pax: [:], rivalPax: Array(m.pax.dropFirst()),
                           rivalCap: Array(m.caps.dropFirst()), referrals: skip ? 0 : m.referrals)
        plan.contract = contractPlan(capacity: cap, marketPax: m.pax[0])
        if wait > 0 { plan.contractWait = wait }
        var left = m.pax[0] + held
        let flagship = state.flagship
        for b in fl.sorted(by: { ($0.id == flagship ? 1 : 0) > ($1.id == flagship ? 1 : 0) }) {
            let n = min(left, state.sellSeats(b))
            plan.pax[b.id] = n
            left -= n
        }
        state.plan = plan
        if let fb = state.balloon(flagship), state.isSelf(fb), plan.flying.contains(fb.id) { return plan.pax[fb.id] ?? 0 }
        return nil
    }

    /// What a special request pays: bigger baskets carry more guests, and festivals pay half as much again.
    /// v124.6: at least 8% of a typical day's net (`dailyNet`), scaled by the mission (the proposal 9%, the panorama
    /// 5%), so it still matters when the company is big; early on the old reward stands. Rounded to 10.
    public func missionReward(_ m: Mission, _ size: BalloonSize? = nil) -> Int {
        let z = size ?? state.balloon(state.flagship)?.size ?? .S
        let byNet = Double(dailyNet) * Rules.missionNetShare * Double(m.reward) / 400
        return jsRound(max(Double(m.reward(for: z)), byNet) * (state.festival != nil ? Rules.festivalReward : 1) / 10) * 10
    }

    /// v124.6: a change in popularity with its reason, logged for the report while `finishDay` runs.
    mutating func rep(_ why: RepReason, _ d: Double) {
        state.rep += d
        if d != 0, repLog != nil { repLog![why, default: 0] += d }
    }

    /// v124.6: logs what changed popularity since `r0` (for steps that clamp it).
    mutating func repMark(_ why: RepReason, since r0: Double) {
        let d = state.rep - r0
        if d != 0, repLog != nil { repLog![why, default: 0] += d }
    }

    // MARK: Day end

    public mutating func finishDay(flight: FlightResult?) -> DayReport {
        guard var plan = state.plan, let weather = state.weather else { preconditionFailure("finishDay before launch") }
        // v124.6: where today's popularity change comes from, for the report
        let repStart = state.rep
        repLog = [:]
        let red = weather.flag == .red
        var ev: [DayEvent] = [], rev: [DayEvent] = []
        var lg = Ledger()
        var accidents: [String] = [], ads: [Sponsor] = []
        var paxTotal = 0
        var flewSelf = false
        let cancelled = flight?.landing == .cancel
        let flyingIDs = plan.flying.filter { state.balloon($0) != nil }

        for id in flyingIDs {
            guard let i = state.balloons.firstIndex(where: { $0.id == id }) else { continue }
            let b = state.balloons[i], z = b.size, pax = plan.pax[id] ?? 0, isSelf = state.isSelf(b)
            paxTotal += pax
            if isSelf && cancelled {
                paxTotal -= pax
                lg.cancellations += pax * Rules.cancelCompensation
                rep(.cancelled, -0.03)
                ev.append(.cancelled(balloon: b.name, pax: pax, compensation: Rules.cancelCompensation))
                continue
            }
            let t = trait(of: b)
            lg.tickets += pax * state.price
            lg.fuel += jsRound(Double(z.fuel) * (state.fuelUpUntil.map { $0 >= state.day } == true ? 1.5 : 1) * (t == .thrifty ? 0.85 : 1))
            switch t {
            case .showman: lg.tips += pax * 9
            case .daredevil: rep(.traits, 0.003)
            case .storyteller:
                rep(.traits, 0.002)
                if rng.chance(0.15) { addReview(.perfect) }
            default: break
            }
            if let sp = b.ad {
                lg.ads += sp.pay(for: z)
                lg.adRepLoss += sp.repLoss
                rep(.ads, -sp.repLoss)
                ads.append(sp)
            }
            let q = premium(z, chance: accidentChance(b))
            if state.insureHull { lg.insurance += q.hull }
            if state.insurePax { lg.insurance += q.pax }

            var severity = 0.0
            let rookie = isSelf && flight != nil && (state.selfFlights ?? 0) < Rules.coachFlights
            if isSelf, let f = flight {
                flewSelf = true
                if !state.licenseValid { ev.append(.licenseRenewedByFlight) }
                state.lastSelfFly = state.day
                lg.founderBonus += jsRound(Double(pax * state.price) * Rules.founderPremium)
                if f.missionDone, let m = f.mission {
                    let reward = missionReward(m, z)
                    lg.mission += reward
                    lg.missionDone = m
                    rep(.mission, 0.02)
                    state.stats = { var st = state.statistics; st.missions += 1; return st }()
                    ev.append(.missionDone(m, reward: reward))
                } else if let m = f.mission {
                    ev.append(.missionFailed(m))
                }
                if let k = f.moment, f.landing != .crash {
                    lg.tips += pax * 5
                    rep(.moment, 0.008)
                    ev.append(.moment(k, tips: pax * 5))
                }
                switch f.landing {
                case .perfect:
                    state.stats = { var st = state.statistics; st.perfectLandings += 1; return st }()
                    lg.tips += pax * 15
                    rep(.perfect, 0.03)
                    ev.append(.perfectLanding(balloon: b.name, tips: pax * 15))
                case .good:
                    lg.tips += pax * 6
                    rep(.good, state.stars > 4.5 ? 0 : 0.01)
                    ev.append(.goodLanding(balloon: b.name))
                case .far:
                    rep(.far, -(state.stars > 4.5 ? 0.04 : 0.02))
                    ev.append(.farLanding(balloon: b.name, meters: jsRound(f.distance)))
                case .hard: severity = 0.3
                case .crash: severity = 0.8
                case .cancel: break
                }
                // v124: Bristol's landings and the airport
                if state.region.bristol { bristolLanding(f, weather: weather, ledger: &lg, events: &ev) }
            } else if rng.chance(accidentChance(b)) {
                severity = rng.range(0.2, 1)
            } else {
                rep(.pilotsSafe, 0.004)
            }

            if severity > 0 {
                let repair = jsRound(Double(z.cost) * 0.35 * severity)
                let comp = jsRound(Double(pax) * 2500 * severity)
                let days0 = rookie ? 1 : 1 + Int((4 * severity).rounded(.up))
                let only = state.balloons.count == 1, days = only ? min(days0, Rules.onlyBalloonRepairDays) : days0
                if only && days < days0 { ev.append(.onlyBalloonRepair(days: Rules.onlyBalloonRepairDays)) }
                if rookie { ev.append(.rookieRepair) }
                let hullPaid = state.insureHull && !red, paxPaid = state.insurePax && !red
                lg.repairs += repair
                lg.compensation += comp
                if hullPaid { lg.insurancePaid += repair }
                if paxPaid { lg.insurancePaid += comp }
                state.balloons[i].damagedUntil = state.day + days
                rep(isSelf ? (severity < 0.5 ? .hard : .crash) : .pilotAccident, -(0.08 + 0.15 * severity))
                if !isSelf { accidents.append(b.name) }
                let who: DayEvent.Pilot = isSelf ? .you : state.pilot(of: b).map { .named($0.name) } ?? .unknown
                if state.bossRival?.alive == true { bossSay(.accident) }
                addPaper(.accident(balloon: b.name, days: days, severe: severity > 0.6))
                let cover: DayEvent.Cover = hullPaid && paxPaid ? .all : hullPaid ? .hullOnly : paxPaid ? .paxOnly : .none
                ev.append(.accident(balloon: b.name, pilot: who, severe: severity > 0.6, days: days, repair: repair, compensation: comp, cover: cover))
            }
        }

        if red && !flyingIDs.isEmpty {
            if rng.chance(Rules.redCatch) {
                lg.fines += Rules.redFine
                state.strikes += 1
                addPaper(.redCaught(fine: Rules.redFine))
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
            state.balloons[i].flights += state.level(.hangar) >= 3 ? 0.85 : 1
            if !isSelf, let pid = state.balloons[i].pilot, let pi = state.pilots.firstIndex(where: { $0.id == pid }) {
                var p = state.pilots[pi]
                p.xp += state.level(.office) >= 3 ? 1.5 : 1
                if let need = p.level.xpToNext, p.xp >= Double(need), let up = PilotLevel(rawValue: p.level.rawValue + 1) {
                    p.level = up
                    p.customWage = Pilot.baseWage(up, school: p.fromSchool, trait: p.trait, region: state.region)
                    ev.append(.pilotPromoted(name: p.name, level: up, wage: p.wage))
                }
                state.pilots[pi] = p
            }
            if state.condition(state.balloons[i]) <= 0 { ev.append(.envelopeWorn(balloon: state.balloons[i].name)) }
        }
        lg.upkeep = jsRound(Double(state.insideBalloons.reduce(0) { $0 + $1.size.upkeep }) * state.upkeepFactor) // v127: none outside the hangar
        let repHotels = state.rep
        for h in state.activeHotels {
            if state.ownHotels.contains(h) {
                lg.hotelIncome += state.hotelIncome(h)
                state.rep = min(1.4, state.rep + h.repPerDay * 1.5)
            } else {
                lg.hotelFees += h.dailyFee
                state.rep = min(1.4, state.rep + h.repPerDay)
            }
        }
        repMark(.hotels, since: repHotels)
        for k in state.loans.indices {
            lg.loans += state.loans[k].installment
            state.loans[k].daysLeft -= 1
        }
        state.loans.removeAll { $0.daysLeft <= 0 }
        // v125: the balloons brought from home, and today's contract groups (yours and the rivals')
        transferPay(&lg)
        contractSettle(plan: &plan, ledger: &lg, events: &ev, rivalEvents: &rev, paxTotal: paxTotal)
        state.plan = plan

        // v124: a Bristol festival day's evening ascent and the Night Glow
        bristolEvening(flying: flyingIDs, cancelledSelf: cancelled, paxTotal: paxTotal, red: red, ledger: &lg, events: &ev)
        state.cash += lg.net
        let repDrift = state.rep
        state.rep = clamp(lerp(state.rep, 1, 0.01), Rules.repRange.lowerBound, Rules.repRange.upperBound)
        if state.stars > 4.5 { state.rep -= 0.006 }
        repMark(.drift, since: repDrift)
        rep(.xl, Double(flyingIDs.compactMap(state.balloon).filter { $0.size == .XL }.count) * Rules.xlRepPerFlight)
        // Painted balloons get talked about; fresh, creative designs most of all.
        let painted = flyingIDs.compactMap(state.balloon).filter { state.design(of: $0) != nil }
        let designRep = min(Studio.maxDailyRep, painted.reduce(0) { acc, b in
            let d = state.design(of: b)!
            return acc + 0.003 * Double(d.score) / 100 * freshness(d) + (d.shape != nil ? 0.0015 : 0)
        })
        if designRep > 0 {
            rep(.designs, designRep)
            lg.designRep = designRep
            if rng.chance(0.25), let d = state.design(of: rng.pick(painted)) { addReview(.design, ["d": String(d.id)]) }
        }
        if flewSelf { state.selfFlights = (state.selfFlights ?? 0) + 1 }
        // v111: the Balloon Show is tonight. A balloon that crashed today (or was sold) drops out; its fee comes back.
        if state.local.showTonight == state.day {
            let ids = state.local.showIDs ?? []
            let keep = ids.filter { id in state.balloon(id).map { $0.damagedUntil <= state.day } ?? false }
            if keep.count < ids.count {
                let refund = ids.filter { id in state.balloon(id) != nil && !keep.contains(id) }.count * Rules.showPerBalloon
                state.local.showIDs = keep
                state.cash += refund
                if refund > 0 { ev.append(.showDropped(refund: refund)) }
            }
            // Too few left for a show: it's called off, every fee comes back and a new one can be booked at once.
            if keep.count < Rules.showMinBalloons {
                let refund = keep.count * Rules.showPerBalloon
                state.cash += refund
                state.local.showTonight = nil
                state.local.showIDs = nil
                state.local.showNext = nil
                state.local.showCount = max(0, (state.local.showCount ?? 1) - 1)
                ev.append(.showCancelled(refund: refund))
            }
        }
        if state.local.showTonight == state.day {
            let n = state.local.showIDs?.count ?? 0
            rep(.show, Rules.showRep)
            state.local.showUntil = state.day + Rules.showDays
            state.local.lastShow = state.day
            ev.append(.showTonight(balloons: n))
            addPaper(.show(balloons: n))
        }
        // Popularity needs hotels or guides past 4.2★; an influencer campaign stretches it to 4.5★. Only once the
        // market (hotels, guides) is open: before that there is nothing the tip could send you to (TestFlight).
        if state.unlocked.contains(.market) && !state.prOK && state.rep > state.prCap {
            let r0 = state.rep
            state.rep = state.prCap
            repMark(.prCap, since: r0)
            queueTip(.prcap)
        }
        if state.licenseDaysLeft == 0 { ev.append(.licenseExpiring) }
        // Passengers miss the founder: popularity erodes while the balloons fly without you.
        let absent = state.daysSinceSelfFly
        if !flyingIDs.isEmpty && absent > Rules.absentGraceDays {
            rep(.absent, -Rules.absentRepLoss)
            if state.absentNoticeDay < state.lastSelfFly || state.day - state.absentNoticeDay >= 5 {
                state.absentNoticeDay = state.day
                ev.append(.founderAbsent(days: absent))
            }
            queueTip(.absent)
        }

        simulateRivals(plan: plan, weather: weather, events: &rev)
        factoryOrderRoll(&rev)

        let rivalPax = plan.rivalPax.reduce(0, +)
        let share = paxTotal + rivalPax > 0 ? Double(paxTotal) / Double(paxTotal + rivalPax) : 0
        if state.day >= 20 && share > 0.6 && state.rivals.contains(where: \.alive) {
            state.monopolyDays += 1
        } else {
            state.monopolyDays = max(0, state.monopolyDays - 1)
        }
        if state.monopolyDays >= 3 { queueTip(.antitrust) }
        // Rivals merge against a player who holds the market, or when one of them is sinking.
        state.dominanceDays = state.day >= 30 && share > 0.5 ? state.dominanceDays + 1 : max(0, state.dominanceDays - 1)
        // Luxor's rivals join forces sooner, more often, and at a smaller share.
        let early = state.region.mergesEarly
        if early && state.day >= 20 && share > 0.38 { state.dominanceDays += 1 }
        let sinking = state.rivals.contains { $0.alive && $0.cash < -4000 } && share > 0.4
        if state.day - (state.lastMerge ?? -99) >= (early ? 15 : 25)
            && ((state.dominanceDays >= (early ? 2 : 4) && rng.chance(early ? 0.5 : 0.35)) || (sinking && rng.chance(0.6))) {
            mergeRivals(share: share, events: &rev)
        }
        // Only on a day the share really was over 60%: a grounded red-flag day must not bring a fine reading 0%.
        if state.monopolyDays >= 5 && share > 0.6 && rng.chance(0.25) {
            // The fine follows company worth, so emptying the cash box doesn't help.
            let worth = max(0, state.cash) + state.balloons.reduce(0) { $0 + $1.size.cost } + state.ownHotels.reduce(0) { $0 + $1.buyPrice }
            let fine = max(Rules.redFine, jsRound(Double(worth) * Rules.monopolyRate / 100) * 100)
            lg.antitrust = fine
            state.cash -= fine
            state.monopolyDays = 0
            addPaper(.antitrust(sharePercent: jsRound(share * 100), fine: fine))
            ev.append(.antitrustFine(sharePercent: jsRound(share * 100), fine: fine))
        }

        if state.cash < Rules.seizeBelow {
            let sellable = state.balloons.filter { $0.id != state.flagship }.sorted { $0.size.cost > $1.size.cost }
            if let take = sellable.first ?? state.balloons.first {
                let v = seizeValue(take)
                state.cash += v
                lg.seizure = v
                state.balloons.removeAll { $0.id == take.id }
                addPaper(.seized(balloon: take.name))
                ev.append(.seized(balloon: take.name, value: v))
                if take.id == state.flagship, let first = state.balloons.first { state.flagship = first.id }
            }
            if state.balloons.isEmpty { state.over = true }
        }

        let flown = flyingIDs.compactMap(state.balloon)
        let capToday = flown.reduce(0) { $0 + state.sellSeats($1) }
        let landedOK = flight.map { $0.missionDone && $0.landing != .hard && $0.landing != .crash } ?? false
        if !flyingIDs.isEmpty && absent > Rules.absentGraceDays && rng.chance(0.3) { addReview(.absent) }
        generateReviews(ReviewContext(xl: flown.contains { $0.size == .XL }, mission: landedOK ? flight?.mission : nil, ads: ads,
                                      landing: flight?.landing, accidents: accidents, red: red, flew: paxTotal > 0,
                                      skipped: plan.skipped, flag: weather.flag))
        for h in state.activeHotels where !state.ownHotels.contains(h) && state.stars < h.minStars - 0.3 {
            state.hotelDeals.removeAll { $0 == h }
            ev.append(.hotelLeft(h))
        }
        if state.day <= state.influencerUntil {
            let r0 = state.rep
            state.rep = min(1.4, state.rep + 0.03)
            repMark(.influencer, since: r0)
            if rng.chance(0.6) { addReview(.influencer) }
        }
        state.repHistory.append(RepPoint(day: state.day, rep: state.rep))
        if state.repHistory.count > 120 { state.repHistory.removeFirst() }
        state.lastShare = MarketShare(me: paxTotal, cap: capToday, rivals: plan.rivalPax, demand: state.demand ?? 0, extra: min(plan.referrals, paxTotal))
        state.netHistory = Array((state.netHistory + [lg.net]).suffix(14))
        loanUnlock()
        runAutopilots()
        lg.holdingNet = holdingDay()
        if state.fiesta != nil && !flyingIDs.isEmpty { state.fiestaFlown += 1 }
        // v121.12: the festival postcard needs a flight in one; the first-flight postcard waits for a flight that didn't
        // end in a crash.
        if state.festival != nil && !flyingIDs.isEmpty { state.local.festivalFlown = true }
        if state.balloons.contains(where: { flyingIDs.contains($0.id) && $0.damagedUntil <= state.day }) { state.firstCleanFlight = true }
        if paxTotal + rivalPax > 0 { state.shareNow = Double(paxTotal) / Double(paxTotal + rivalPax) }
        lg.chapterReward = checkChapters(events: &ev)
        if paxTotal > (state.bestPax ?? 0) && state.day > 5 {
            if let best = state.bestPax, best > 0, paxTotal >= best + 8 { addPaper(.record(pax: paxTotal)) }
            state.bestPax = paxTotal
        }
        if let boss = state.bossRival, boss.alive, boss.lastPax > 0, paxTotal > boss.lastPax, state.day > 8 {
            if !bossSaid(.passed) { addPaper(.passedBoss(rival: boss.name)) }
            bossSay(.passed)
        }
        state.stats = { var st = state.statistics; st.passengers += paxTotal; return st }()
        praiseCheck(flight: cancelled ? nil : flight, waitedOutRed: red && flyingIDs.isEmpty)
        // v121: after the first flight in Cappadocia, Hezarfen tells the grandfather's story
        if state.region == .cap && !flyingIDs.isEmpty && state.day <= 3 { queueTip(.hasan) }
        factoryDay(&ev, tomorrow: state.day + 1)
        var report = DayReport(day: state.day, flag: weather.flag, ledger: lg, events: ev, rivalEvents: rev,
                               passengers: paxTotal, capacity: capToday, skipped: plan.skipped)
        report.repFrom = repStart
        report.repTo = state.rep
        report.repWhy = repLog
        repLog = nil

        state.day += 1
        state.plan = nil
        milestoneCheck()
        checkAchievements()
        if state.anyBaron { checkHoldingGoals() }
        if state.region.hasFiesta {
            if let f = state.fiesta, state.day > f.end {
                state.fiesta = nil
                state.fiestaNext = state.day + state.region.fiestaEvery
            } else if state.fiesta == nil && state.day >= (state.fiestaNext ?? 0) && (state.winter == nil || state.region == .lux) {
                state.fiesta = Fiesta(start: state.day, end: state.day + state.region.fiestaDays - 1)
                state.hezQueue.append(.fiestaStarted)
                if state.region.bristol { addPaper(.briFestival) }
            }
        }
        if state.region.hasFestivals {
            if let f = state.festival, state.day > f.end {
                state.festival = nil
            } else if state.festival == nil && state.winter == nil && state.day >= (state.festivalNext ?? Rules.festivalFirst) {
                let n = state.festivalCount ?? 0
                state.festival = Festival(index: n % Rules.festivalCount, start: state.day, end: state.day + Rules.festivalDays - 1)
                state.festivalCount = n + 1
                state.festivalNext = state.day + Rules.festivalEvery
                state.hezQueue.append(.festivalStarted(n % Rules.festivalCount))
                addPaper(.festival(n % Rules.festivalCount))
            }
        }
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
        // v125: after the weather, so a red flag moves today's tour group; the cargo from home
        contractMorning()
        transferArrive()
        planRivalFlights()
        unlockCheck()
        assignPilots()
        return report
    }
}
