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

    mutating func addBalloon(_ size: BalloonSize, secondHand: Bool = false) {
        let used = Set(state.balloons.map(\.name))
        let name = size == .XL ? state.region.xlName : state.region.balloonNames.first { !used.contains($0) } ?? "Balloon \(state.nextID)"
        var b = Balloon(id: state.nextID, size: size, name: name)
        if secondHand { b.used = true }
        state.balloons.append(b)
        state.nextID += 1
    }

    /// What a balloon fetches when you sell it: 60% of the price new, 40% if it came from a rival.
    public func sellValue(_ b: Balloon) -> Int {
        jsRound(Double(b.size.cost) * (b.used == true ? Rules.usedSellShare : Rules.sellShare))
    }

    /// What the bank gets for a seized balloon: half the price new, 30% if second-hand.
    public func seizeValue(_ b: Balloon) -> Int {
        jsRound(Double(b.size.cost) * (b.used == true ? Rules.usedSeizeShare : Rules.seizeShare))
    }

    @discardableResult
    public mutating func sellBalloon(_ id: Int) -> Bool {
        guard state.balloons.count > 1, let b = state.balloon(id) else { return false }
        state.cash += sellValue(b)
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

    /// v111: your own name for a balloon (the default one stays until you change it). Spaces are tidied,
    /// at most `Rules.balloonNameMax` characters, and no two of your balloons share a name.
    public enum RenameResult: Sendable { case ok, empty, taken }

    @discardableResult
    public mutating func renameBalloon(_ id: Int, _ raw: String) -> RenameResult {
        let name = String(raw.split(whereSeparator: \.isWhitespace).joined(separator: " ").prefix(Rules.balloonNameMax))
        guard !name.isEmpty else { return .empty }
        guard let i = state.balloons.firstIndex(where: { $0.id == id }) else { return .empty }
        if state.balloons.contains(where: { $0.id != id && $0.name.compare(name, options: .caseInsensitive) == .orderedSame }) { return .taken }
        state.balloons[i].name = name
        return .ok
    }

    /// v111: "I'll fly this balloon": it becomes the flagship and you fly it yourself.
    @discardableResult
    public mutating func flyMyself(_ id: Int) -> Bool {
        guard let b = state.balloon(id), b.damagedUntil <= state.day, state.condition(b) > 0 else { return false }
        state.flagship = id
        state.selfFly = true
        assignPilots()
        return true
    }

    public mutating func makeFlagship(_ id: Int) {
        guard state.balloon(id) != nil else { return }
        state.flagship = id
        assignPilots()
    }

    // MARK: Temporary flagship (v110)

    /// While the flagship you fly is in repair: the balloons you could fly instead, biggest first.
    /// Empty once you've been asked about this repair, or while you already fly another one.
    public var tempFlagshipCandidates: [Balloon] {
        let s = state
        guard let fb = s.balloon(s.flagship), fb.damagedUntil > s.day, s.flyingSelf, s.local.banUntil < s.day, s.local.flagReturn == nil,
              s.local.flagAskedUntil != fb.damagedUntil else { return [] }
        return s.balloons.enumerated()
            .filter { $0.element.id != fb.id && $0.element.damagedUntil <= s.day && s.condition($0.element) > 0 }
            .sorted { ($1.element.size.capacity, $0.offset) < ($0.element.size.capacity, $1.offset) }
            .map(\.element)
    }

    /// The offer is made once per repair, whatever the answer.
    public mutating func markTempFlagshipAsked() {
        if let fb = state.balloon(state.flagship) { state.local.flagAskedUntil = fb.damagedUntil }
    }

    /// Yes: you fly `id` until the flagship is out of repair; then it's the flagship again by itself.
    @discardableResult
    public mutating func flyTempFlagship(_ id: Int) -> Bool {
        guard state.local.flagReturn == nil, let fb = state.balloon(state.flagship), fb.damagedUntil > state.day,
              let b = state.balloon(id), b.id != fb.id, b.damagedUntil <= state.day, state.condition(b) > 0 else { return false }
        markTempFlagshipAsked()
        state.local.flagReturn = FlagReturn(original: fb.id, temp: id)
        state.flagship = id
        state.selfFly = true
        assignPilots()
        return true
    }

    /// Each morning: once the real flagship is repaired it's the flagship again, unless you changed the flagship meanwhile.
    mutating func flagReturnCheck() {
        guard let r = state.local.flagReturn else { return }
        guard let orig = state.balloon(r.original), state.flagship == r.temp else { state.local.flagReturn = nil; return }
        if orig.damagedUntil <= state.day {
            state.flagship = orig.id
            state.local.flagReturn = nil
            state.hezQueue.append(.flagshipBack(orig.name))
            assignPilots()
        }
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
        // Who pays rather than flies wants the pilots to fly (v110): the pilots-only choice is the one offered,
        // unless no pilot is free for the flagship.
        state.selfFly = false
        assignPilots()
        if let fb = state.balloon(state.flagship), state.status(fb) == .noPilot {
            state.selfFly = true
            assignPilots()
        }
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
        state.balloons.count >= offer.balloonsNeeded && state.loans.count < Rules.maxLoans && loanOpen(offer)
    }

    public func loanOpen(_ offer: LoanOffer) -> Bool {
        offer.minDailyNet == 0 || (state.local.loansOpen ?? []).contains(offer.amount)
    }

    /// Each evening: a big loan opens for good the first time the region earns enough.
    mutating func loanUnlock() {
        var open = state.local.loansOpen ?? []
        for o in Rules.loans where o.minDailyNet > 0 && !open.contains(o.amount) && dailyNet >= o.minDailyNet {
            open.append(o.amount)
        }
        if !open.isEmpty { state.local.loansOpen = open }
    }

    // MARK: Purchase loan

    public struct BuyLoanTerms: Equatable, Sendable {
        public let price: Int, own: Int, financed: Int, installment: Int, days: Int
        public var total: Int { installment * days }
    }

    /// What the bank would lend to buy something at `price`, or nil when the purchase loan can't be used.
    public func buyLoanTerms(price: Int) -> BuyLoanTerms? {
        guard state.unlocked.contains(.bank), state.balloons.count >= Rules.buyLoanBalloons, state.loans.count < Rules.maxLoans, !state.loans.contains(where: { $0.purchase == true }),
              (state.local.loansOpen ?? []).contains(100_000) else { return nil }
        let own = max(0, min(price, state.cash - Rules.buyLoanReserve)), fin = price - own
        guard fin > 0, fin <= Rules.buyLoanMax, Double(own) >= Double(price) * Rules.buyLoanDown else { return nil }
        let inst = Int((Double(fin) * (1 + Rules.buyLoanRate) / Double(Rules.buyLoanDays) / 10).rounded(.up)) * 10
        return BuyLoanTerms(price: price, own: own, financed: fin, installment: inst, days: Rules.buyLoanDays)
    }

    /// Price of rival `i`: its take-over offer, or its bankrupt fleet.
    public func dealPrice(_ i: Int, bankrupt: Bool) -> Int? {
        guard state.rivals.indices.contains(i) else { return nil }
        return bankrupt ? state.rivals[i].forSale?.price : (state.rivals[i].alive ? state.rivals[i].offer : nil)
    }

    /// Buy rival `i` (or its bankrupt fleet) with the purchase loan: the bank pays the seller the financed part.
    @discardableResult
    public mutating func buyWithLoan(_ i: Int, bankrupt: Bool) -> Bool {
        guard let price = dealPrice(i, bankrupt: bankrupt), let t = buyLoanTerms(price: price) else { return false }
        state.cash += t.financed
        let ok = bankrupt ? buyBankruptFleet(i) : takeOver(i)
        guard ok else { state.cash -= t.financed; return false }
        state.loans.append(Loan(amount: t.financed, installment: t.installment, daysLeft: t.days, purchase: true))
        return true
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

    /// Signing pays three days up front. On the rescue card (`inRescue`) cash may go below zero, as long as it stays
    /// above the bank's seizure line.
    @discardableResult
    public mutating func signHotel(_ h: Hotel, inRescue: Bool = false) -> Bool {
        let fee = h.dailyFee * 3
        guard !state.hotelActive(h), state.stars >= h.minStars, hotelLockedByRival(h) == nil, hotelRivalOwner(h) == nil,
              state.cash - fee >= (inRescue ? Rules.seizeBelow : 0) else { return false }
        state.cash -= fee
        state.hotelDeals.append(h)
        return true
    }

    public mutating func endHotelDeal(_ h: Hotel) { state.hotelDeals.removeAll { $0 == h } }

    /// What an owned hotel sells for: `Rules.hotelSellShare` of its price.
    public func hotelSellValue(_ h: Hotel) -> Int { jsRound(Double(h.buyPrice) * Rules.hotelSellShare / 100) * 100 }

    /// Who buys a hotel you sell: the strongest rival still flying (nil: none, the hotel goes back on the market).
    public var hotelBuyer: String? { state.rivals.filter(\.alive).max { $0.rep < $1.rep }?.name }

    /// The rival that owns a hotel you sold, while it's still in business: no deals with that hotel any more, only
    /// buying it back (`hotelBuyPrice`).
    public func hotelRivalOwner(_ h: Hotel) -> String? {
        guard let n = state.hotelOwners?[h], state.rivals.contains(where: { $0.alive && $0.name == n }) else { return nil }
        return n
    }

    /// What a hotel costs to buy: from its rival owner, `Rules.hotelRivalMarkup` more.
    public func hotelBuyPrice(_ h: Hotel) -> Int {
        hotelRivalOwner(h) == nil ? h.buyPrice : jsRound(Double(h.buyPrice) * Rules.hotelRivalMarkup / 100) * 100
    }

    /// A rival left the market: the hotels it bought from you come to you if you bought the company (`takenOver`),
    /// otherwise each is offered to you once, cheap (`pendingHotelBargain`); declined, it's free on the market again.
    mutating func rivalGone(_ name: String, takenOver: Bool) {
        guard let owners = state.hotelOwners else { return }
        for (h, n) in owners where n == name {
            state.hotelOwners?[h] = nil
            if takenOver {
                if !state.ownHotels.contains(h) { state.ownHotels.append(h) }
            } else {
                let price = jsRound(Double(h.buyPrice) * Rules.hotelBargainShare / 100) * 100
                state.hotelBargains = (state.hotelBargains ?? []) + [HotelBargain(hotel: h, rival: name, price: price)]
            }
        }
    }

    /// The bankrupt rival's hotel waiting for an answer.
    public var pendingHotelBargain: HotelBargain? { state.hotelBargains?.first }

    /// Buy the bargain hotel (if the cash is there) or pass; either way the offer goes.
    @discardableResult
    public mutating func answerHotelBargain(buy: Bool) -> Bool {
        guard let b = state.hotelBargains?.first else { return false }
        state.hotelBargains?.removeFirst()
        guard buy, state.cash >= b.price, !state.ownHotels.contains(b.hotel) else { return false }
        state.cash -= b.price
        state.ownHotels.append(b.hotel)
        state.hotelDeals.removeAll { $0 == b.hotel }
        state.hotelLocks[b.hotel] = nil
        return true
    }

    /// Sells an owned hotel to the strongest rival: the money comes at once, its room income and guests stop, and
    /// from then on it can only be bought back from that rival.
    @discardableResult
    public mutating func sellHotel(_ h: Hotel) -> Bool {
        guard state.ownHotels.contains(h) else { return false }
        state.ownHotels.removeAll { $0 == h }
        state.cash += hotelSellValue(h)
        state.hotelLocks[h] = nil
        if let b = hotelBuyer {
            var o = state.hotelOwners ?? [:]
            o[h] = b
            state.hotelOwners = o
        }
        return true
    }

    @discardableResult
    public mutating func buyHotel(_ h: Hotel) -> Bool {
        let price = hotelBuyPrice(h)
        guard !state.ownHotels.contains(h), state.stars >= h.minStars, state.cash >= price else { return false }
        state.cash -= price
        state.ownHotels.append(h)
        state.hotelDeals.removeAll { $0 == h }
        state.hotelLocks[h] = nil
        state.hotelOwners?[h] = nil
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
    public mutating func runGuideFlight(inRescue: Bool = false) -> Bool {
        guard state.guideCooldown <= state.day, state.cash - Rules.guideCost >= (inRescue ? Rules.seizeBelow : 0) else { return false }
        state.cash -= Rules.guideCost
        state.rep = min(1.4, state.rep + 0.05)
        state.guideCooldown = state.day + 5
        state.guideUntil = state.day + 3
        state.guideCount += 1
        state.lastGuide = state.day
        addReview(.guide)
        return true
    }

    /// Rescue card: the guides' flight, when the market is open, it's off cooldown and paying keeps cash above seizure.
    public var rescueGuideOK: Bool {
        state.unlocked.contains(.guide) && state.guideCooldown <= state.day && state.cash - Rules.guideCost >= Rules.seizeBelow
    }

    /// Rescue card: the best hotel deal the player can sign right now, only when there's no deal yet; paying keeps cash
    /// above seizure.
    public var rescueHotel: Hotel? {
        guard state.unlocked.contains(.market), state.hotelDeals.isEmpty else { return nil }
        return Hotel.allCases.reversed().first {
            !state.hotelActive($0) && state.stars >= $0.minStars && hotelLockedByRival($0) == nil && hotelRivalOwner($0) == nil
                && state.cash - $0.dailyFee * 3 >= Rules.seizeBelow
        }
    }

    /// Rescue card: the smallest hotel you own, to sell (the best ones stay).
    public var rescueSellHotel: Hotel? { state.ownHotels.min { $0.buyPrice < $1.buyPrice } }

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

    /// The pilots that come with a take-over or a bankrupt fleet join your crew, on their contracts.
    mutating func hireCrew(_ crew: [Pilot]) {
        for var p in crew {
            p.id = state.nextID
            state.nextID += 1
            state.pilots.append(p)
        }
    }

    /// Buy a struggling rival outright: its balloons and pilots join you and it leaves the market.
    @discardableResult
    public mutating func takeOver(_ i: Int) -> Bool {
        guard state.rivals.indices.contains(i), let price = state.rivals[i].offer, state.rivals[i].alive, state.cash >= price else { return false }
        state.cash -= price
        state.rivals[i].balloons.forEach { addBalloon($0, secondHand: true) }
        hireCrew(state.dealCrew(i, bankrupt: false))
        rivalGone(state.rivals[i].name, takenOver: true)
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
        sale.sizes.forEach { addBalloon($0, secondHand: true) }
        hireCrew(state.dealCrew(i, bankrupt: true))
        state.rivals[i].forSale = nil
        assignPilots()
        return true
    }
}
