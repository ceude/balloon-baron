import Foundation

/// v133: going bankrupt. While cash closes a day below `Rules.seizeBelow` the bank takes one balloon a day, the biggest
/// that isn't the flagship first (`Game.finishDay`). The flagship only goes once cash has closed
/// `Rules.flagshipGraceDays` days in a row below the line (`RegionState.debtDays`; a day that closes above starts the
/// count again). Without a holding that ends the game as before. With one, losing the last balloon only closes the
/// region: the holding can rescue it once per region (`rescueQuote`), or the region's company is wound up
/// (`closeRegion`) and you go on in your other regions, or start this one afresh when it was your only one.
public enum Bankruptcy {
    /// The rescue puts the region's cash back up to this (in the region's money)...
    public static let rescueTarget = 10000
    /// ...for this many times the money put in, in euros, or this share of the holding's cash, whichever is more, and
    /// never less than `rescueMin`. v134 (TestFlight: "otherwise it's an infinite extra life"): a quarter and €250,000
    /// (v133: a tenth and €100,000). tools/sim-bankrupt.js: holdings are ~€3 million when it fires.
    public static let rescueMultiplier = 3.0
    public static let rescueHoldingShare = 0.25
    public static let rescueMin = 250000
    /// v134: the bailout is news; the region's popularity drops by this much (0.125 = half a star).
    public static let rescueRepLoss = 0.125
}

/// What the holding's rescue would cost now.
public struct RescueQuote: Equatable, Sendable {
    /// Money put into the region's cash (its own currency) and the price in the holding's euros.
    public var added: Int
    public var cost: Int
    /// The day the holding already rescued this region (no second rescue).
    public var usedOn: Int?
    /// The holding's cash now.
    public var holdingCash: Int
    /// v134: the region's popularity now and after the rescue.
    public var repFrom: Double
    public var repTo: Double
    public var affordable: Bool { usedOn == nil && holdingCash >= cost }
    public var holdingAfter: Int { holdingCash - cost }
}

extension GameState {
    /// The holding exists once you're a baron (Cappadocia's ceremony opens it).
    public var hasHolding: Bool { anyBaron }
    /// The flagship is all the bank has left to take.
    public var flagshipNext: Bool {
        local.cash < Rules.seizeBelow && !local.balloons.isEmpty && local.balloons.allSatisfy { $0.id == local.flagship }
    }
    /// Closes of the day below the line before the bank takes the flagship (1: tonight).
    public var graceDaysLeft: Int { max(1, Rules.flagshipGraceDays - (local.debtDays ?? 0)) }
    /// The day the region's company closed, while it stays closed.
    public func closedOn(_ r: RegionID) -> Int? { holding.closed?[r] }

    public var rescueQuote: RescueQuote {
        let added = max(0, Bankruptcy.rescueTarget - local.cash)
        let euros = Double(added) / region.fx * Bankruptcy.rescueMultiplier
        let share = Double(max(0, holding.cash)) * Bankruptcy.rescueHoldingShare
        let cost = max(Bankruptcy.rescueMin, Int((euros / 1000).rounded(.up)) * 1000, Int((share / 1000).rounded(.up)) * 1000)
        return RescueQuote(added: added, cost: cost, usedOn: holding.rescued?[region], holdingCash: holding.cash,
                           repFrom: local.rep, repTo: max(Rules.repRange.lowerBound, local.rep - Bankruptcy.rescueRepLoss))
    }

    /// Where a closed region's player goes: the other region with the biggest fleet (nil: this one starts afresh).
    public var ruinNext: RegionID? {
        RegionID.allCases.filter { parked[$0] != nil }
            .max { (parked[$0]!.state.balloons.count, -RegionID.allCases.firstIndex(of: $0)!) < (parked[$1]!.state.balloons.count, -RegionID.allCases.firstIndex(of: $1)!) }
    }
}

extension Game {
    /// The holding pays and the region's cash goes back up to `Bankruptcy.rescueTarget`. Once per region, for good:
    /// `Holding.rescued` is never cleared, not even when the region closes and is entered again. v134: the region's
    /// popularity drops by `Bankruptcy.rescueRepLoss`.
    @discardableResult
    public mutating func acceptHoldingRescue() -> Bool {
        let q = state.rescueQuote
        guard state.ruinPending != nil, q.affordable, spendHolding(q.cost) else { return false }
        state.holding.rescued = (state.holding.rescued ?? [:]).merging([state.region: state.day]) { _, b in b }
        state.local.cash += q.added
        state.rep = q.repTo
        state.local.debtDays = nil
        state.ruinPending = nil
        state.rescueShown = nil
        state.hezQueue.append(.holdingRescued(state.region, cost: q.cost, added: q.added))
        addPaper(.holdingRescue(state.region))
        return true
    }

    /// The region's company is wound up: the bank takes everything there. You go on in the other region with the biggest
    /// fleet; with no other region a new company starts here, free, from a small balloon. The holding, the other
    /// regions, the baron titles and the save stay.
    public mutating func closeRegion() {
        guard state.ruinPending != nil else { return }
        let r = state.region
        state.ruinPending = nil
        state.holding.closed = (state.holding.closed ?? [:]).merging([r: state.day]) { _, b in b }
        // nothing booked for tonight goes up in a closed region (its fee went with the company)
        state.local.showTonight = nil
        state.local.showIDs = nil
        state.local.glowTonight = nil
        state.local.openIssue = nil
        state.transferAsk = nil
        addPaper(.regionClosed(r))
        if let to = state.ruinNext {
            state.hezQueue.append(.regionClosed(r, fresh: false, fee: r.entryFee))
            switchRegion(to)
            state.parked[r] = nil
        } else {
            state.hezQueue.append(.regionClosed(r, fresh: true, fee: 0))
            state.holding.closed?[r] = nil
            if state.holding.closed?.isEmpty == true { state.holding.closed = nil }
            var next = newRegionState(r)
            state.nextID += 1
            next.weather = nil
            next.demand = nil
            next.plan = nil
            next.candidates = []
            next.rivalPlanDay = 0
            state.local = next
            startDay()
        }
    }
}
