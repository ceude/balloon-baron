import Foundation

/// Everything the player can do from the office. Each returns false when not allowed.
extension Game {
    // MARK: Pricing and flying

    public mutating func setPrice(_ p: Int) { state.price = clamp(p, Rules.priceRange.lowerBound, Rules.priceRange.upperBound) }

    public mutating func setFlying(_ id: Int, _ on: Bool) {
        guard let i = state.balloons.firstIndex(where: { $0.id == id }) else { return }
        state.balloons[i].fly = on
    }

    public mutating func setSelfFly(_ on: Bool) {
        state.selfFly = on
        assignPilots()
    }

    public mutating func setInsurance(hull: Bool? = nil, pax: Bool? = nil) {
        if let hull { state.insureHull = hull }
        if let pax { state.insurePax = pax }
    }

    // MARK: Fleet

    @discardableResult
    public mutating func buyBalloon(_ size: BalloonSize) -> Bool {
        guard state.cash >= size.cost, size != .XL || !state.balloons.contains(where: { $0.size == .XL }) else { return false }
        state.cash -= size.cost
        addBalloon(size)
        assignPilots()
        return true
    }

    mutating func addBalloon(_ size: BalloonSize) {
        let used = Set(state.balloons.map(\.name))
        let name = size == .XL ? state.region.xlName : state.region.balloonNames.first { !used.contains($0) } ?? "Balloon \(state.nextID)"
        state.balloons.append(Balloon(id: state.nextID, size: size, name: name))
        state.nextID += 1
    }

    @discardableResult
    public mutating func sellBalloon(_ id: Int) -> Bool {
        guard state.balloons.count > 1, let b = state.balloon(id) else { return false }
        state.cash += jsRound(Double(b.size.cost) * Rules.sellShare)
        state.balloons.removeAll { $0.id == id }
        if state.flagship == id { state.flagship = state.balloons[0].id }
        assignPilots()
        return true
    }

    public func renewCost(_ b: Balloon) -> Int { jsRound(Double(b.size.cost) * Rules.renewShare) }

    /// Price of the next burner for a balloon, nil at three.
    public func burnerCost(_ b: Balloon) -> Int? { b.burners < 3 ? jsRound(Double(b.size.cost) * Burners.cost[b.burners]) : nil }
    public func turningVentCost(_ b: Balloon) -> Int { jsRound(Double(b.size.cost) * Burners.turningVentCost) }

    @discardableResult
    public mutating func addBurner(_ id: Int) -> Bool {
        guard let i = state.balloons.firstIndex(where: { $0.id == id }), let cost = burnerCost(state.balloons[i]), state.cash >= cost else { return false }
        state.cash -= cost
        state.balloons[i].burner = state.balloons[i].burners + 1
        return true
    }

    @discardableResult
    public mutating func fitTurningVent(_ id: Int) -> Bool {
        guard let i = state.balloons.firstIndex(where: { $0.id == id }), !state.balloons[i].hasTurningVent else { return false }
        let cost = turningVentCost(state.balloons[i])
        guard state.cash >= cost else { return false }
        state.cash -= cost
        state.balloons[i].turningVent = true
        return true
    }

    @discardableResult
    public mutating func renewEnvelope(_ id: Int) -> Bool {
        guard let i = state.balloons.firstIndex(where: { $0.id == id }) else { return false }
        let cost = renewCost(state.balloons[i])
        guard state.cash >= cost else { return false }
        state.cash -= cost
        state.balloons[i].flights = 0
        assignPilots()
        return true
    }

    /// Balloons whose envelope is below 30%: the fleet page renews them all with one tap.
    public var wornBalloons: [Balloon] { state.balloons.filter { state.condition($0) < 0.3 } }
    public var renewWornCost: Int { wornBalloons.reduce(0) { $0 + renewCost($1) } }

    @discardableResult
    public mutating func renewWornEnvelopes() -> Bool {
        let worn = wornBalloons, cost = renewWornCost
        guard !worn.isEmpty, state.cash >= cost else { return false }
        state.cash -= cost
        for b in worn { if let i = state.balloons.firstIndex(where: { $0.id == b.id }) { state.balloons[i].flights = 0 } }
        assignPilots()
        return true
    }

    public mutating func makeFlagship(_ id: Int) {
        guard state.balloon(id) != nil else { return }
        state.flagship = id
        assignPilots()
    }

    @discardableResult
    public mutating func setAd(_ id: Int, _ sponsor: Sponsor?) -> Bool {
        guard let i = state.balloons.firstIndex(where: { $0.id == id }) else { return false }
        if let sponsor, !sponsor.allowed(on: state.balloons[i].size) { return false }
        state.balloons[i].ad = sponsor
        return true
    }

    public mutating func removeAllAds() {
        for i in state.balloons.indices { state.balloons[i].ad = nil }
    }

    // MARK: Crew

    @discardableResult
    public mutating func hire(_ id: Int) -> Bool {
        guard let p = state.candidates.first(where: { $0.id == id }) else { return false }
        state.pilots.append(p)
        state.candidates.removeAll { $0.id == id }
        assignPilots()
        return true
    }

    public mutating func fire(_ id: Int) {
        state.pilots.removeAll { $0.id == id }
        assignPilots()
    }

    @discardableResult
    public mutating func renewLicense() -> Bool {
        guard state.cash >= Rules.recertCost else { return false }
        state.cash -= Rules.recertCost
        state.lastSelfFly = state.day
        state.selfFly = true
        assignPilots()
        return true
    }

    @discardableResult
    public mutating func buildSchool() -> Bool {
        guard !state.school, state.cash >= Rules.schoolCost else { return false }
        state.cash -= Rules.schoolCost
        state.school = true
        newCandidates()
        return true
    }

    /// Answer a rival's offer to your pilot: match the wage or let them go.
    public mutating func answerPoach(match: Bool) {
        guard let offer = state.poach else { return }
        state.poach = nil
        guard let i = state.pilots.firstIndex(where: { $0.id == offer.pilotID }) else { return }
        if match {
            state.pilots[i].customWage = offer.wage
        } else {
            state.pilots.remove(at: i)
            assignPilots()
        }
    }

    // MARK: Bank

    public func canTakeLoan(_ offer: LoanOffer) -> Bool {
        state.balloons.count >= offer.balloonsNeeded && state.loans.count < Rules.maxLoans && dailyNet >= offer.minDailyNet
    }

    /// The region's typical day lately: the median net of the last 14 days (0 with less than a week of history).
    public var dailyNet: Int {
        let h = state.local.netHistory.suffix(14).sorted()
        return h.count >= 7 ? h[h.count / 2] : 0
    }

    @discardableResult
    public mutating func takeLoan(_ index: Int) -> Bool {
        guard Rules.loans.indices.contains(index) else { return false }
        let o = Rules.loans[index]
        guard canTakeLoan(o) else { return false }
        state.cash += o.amount
        state.loans.append(Loan(amount: o.amount, installment: o.installment, daysLeft: o.days))
        return true
    }

    @discardableResult
    public mutating func repayLoan(_ index: Int) -> Bool {
        guard state.loans.indices.contains(index), state.cash >= state.loans[index].payoff else { return false }
        state.cash -= state.loans[index].payoff
        state.loans.remove(at: index)
        return true
    }

    // MARK: Hotels and marketing

    public func hotelLockedByRival(_ h: Hotel) -> HotelLock? {
        guard let l = state.hotelLocks[h], l.until > state.day, !state.hotelActive(h) else { return nil }
        return l
    }

    /// Signing pays three days up front.
    @discardableResult
    public mutating func signHotel(_ h: Hotel) -> Bool {
        let fee = h.dailyFee * 3
        guard !state.hotelActive(h), state.stars >= h.minStars, hotelLockedByRival(h) == nil, state.cash >= fee else { return false }
        state.cash -= fee
        state.hotelDeals.append(h)
        return true
    }

    public mutating func endHotelDeal(_ h: Hotel) { state.hotelDeals.removeAll { $0 == h } }

    @discardableResult
    public mutating func buyHotel(_ h: Hotel) -> Bool {
        guard !state.ownHotels.contains(h), state.stars >= h.minStars, state.cash >= h.buyPrice else { return false }
        state.cash -= h.buyPrice
        state.ownHotels.append(h)
        state.hotelDeals.removeAll { $0 == h }
        state.hotelLocks[h] = nil
        return true
    }

    @discardableResult
    public mutating func runInfluencer() -> Bool {
        let cost = state.influencerCost
        guard state.influencerCooldown <= state.day, state.cash >= cost else { return false }
        state.cash -= cost
        state.rep = min(1.4, state.rep + 0.1)
        state.influencerUntil = state.day + 3
        state.influencerCooldown = state.day + 10
        state.influencerCount += 1
        addReview(.influencer)
        queueTip(.influ)
        return true
    }

    @discardableResult
    public mutating func runGuideFlight() -> Bool {
        guard state.guideCooldown <= state.day, state.cash >= Rules.guideCost else { return false }
        state.cash -= Rules.guideCost
        state.rep = min(1.4, state.rep + 0.05)
        state.guideCooldown = state.day + 5
        state.guideUntil = state.day + 3
        state.guideCount += 1
        state.lastGuide = state.day
        addReview(.guide)
        return true
    }

    // MARK: Rival deals

    /// A struggling rival or a bankrupt fleet the player hasn't answered yet.
    public var pendingDeal: (rival: Int, bankrupt: Bool)? {
        for (i, r) in state.rivals.enumerated() {
            if r.alive && r.offer != nil && !r.offerSeen && !r.offerDeclined { return (i, false) }
            if r.forSale != nil && !r.saleSeen && !r.saleDeclined { return (i, true) }
        }
        return nil
    }

    public mutating func markDealSeen(_ i: Int, bankrupt: Bool) {
        if bankrupt { state.rivals[i].saleSeen = true } else { state.rivals[i].offerSeen = true }
    }

    public mutating func declineDeal(_ i: Int, bankrupt: Bool) {
        if bankrupt { state.rivals[i].saleDeclined = true } else { state.rivals[i].offerDeclined = true }
    }

    /// Buy a struggling rival outright: its balloons join you and it leaves the market.
    @discardableResult
    public mutating func takeOver(_ i: Int) -> Bool {
        guard state.rivals.indices.contains(i), let price = state.rivals[i].offer, state.rivals[i].alive, state.cash >= price else { return false }
        state.cash -= price
        state.rivals[i].balloons.forEach { addBalloon($0) }
        state.rivals[i].alive = false
        state.rivals[i].deadDay = state.day
        state.rivals[i].forSale = nil
        state.rivals[i].offer = nil
        assignPilots()
        return true
    }

    @discardableResult
    public mutating func buyBankruptFleet(_ i: Int) -> Bool {
        guard state.rivals.indices.contains(i), let sale = state.rivals[i].forSale, state.cash >= sale.price else { return false }
        state.cash -= sale.price
        sale.sizes.forEach { addBalloon($0) }
        state.rivals[i].forSale = nil
        assignPilots()
        return true
    }
}
