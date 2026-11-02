import Foundation

/// v111: the Balloon Show (`showCard`, `bookShow`). Every balloon that can fly lights up over the town one night:
/// paid per balloon, all of them or none, once every `Rules.showCooldown` days from `Rules.showMinBalloons` balloons.
public enum ShowState: Equatable, Sendable {
    case locked, booked, few, cash, ok
    case wait(days: Int)
    /// v132: Bristol's Night Glow is booked tonight; the show can't take its night.
    case glow
}

extension Game {
    /// The balloons that would take part: every one that can fly tonight.
    public var showFleet: [Balloon] { state.insideBalloons.filter { $0.damagedUntil <= state.day && state.condition($0) > 0 } } // v127: not outside the hangar
    public var showCost: Int { Rules.showPerBalloon * showFleet.count }

    public var showState: ShowState {
        let l = state.local
        if !state.unlocked.contains(.market) { return .locked }
        if l.showTonight == state.day { return .booked }
        if let next = l.showNext, next > state.day { return .wait(days: next - state.day) }
        if l.glowTonight == state.day { return .glow }
        if showFleet.count < Rules.showMinBalloons { return .few }
        return state.cash < showCost ? .cash : .ok
    }

    /// Show tourists a day before the price: `showPax` per balloon that took part.
    var showTourists: Double { Rules.showPax * Double(state.local.showIDs?.count ?? 0) }

    @discardableResult
    public mutating func bookShow() -> Bool {
        guard showState == .ok else { return false }
        let ids = showFleet.map(\.id)
        state.cash -= Rules.showPerBalloon * ids.count
        state.local.showTonight = state.day
        state.local.showIDs = ids
        state.local.showNext = state.day + Rules.showCooldown
        state.local.showCount = (state.local.showCount ?? 0) + 1
        state.tipsSeen.insert(.show)
        return true
    }

    /// v111 / v132: balloons that can't go up tonight (crashed, sold, or taken by the bank) drop out of the show and their
    /// fees come back; with fewer than `Rules.showMinBalloons` left the show is called off, every fee comes back and a
    /// new one can be booked at once. Each step is a line in the report, and the report shows the cancellation in a box.
    mutating func showDropOut(_ out: [Int], ledger lg: inout Ledger, events ev: inout [DayEvent], seized: Bool = false) {
        guard state.local.showTonight == state.day, let ids = state.local.showIDs else { return }
        let gone = ids.filter(out.contains)
        let keep = ids.filter { !gone.contains($0) }
        if !gone.isEmpty {
            // a crashed or seized balloon's fee comes back; a sold one's went with the sale (as before)
            let refund = gone.filter { seized || state.balloon($0) != nil }.count * Rules.showPerBalloon
            state.local.showIDs = keep
            state.cash += refund
            if refund > 0 {
                lg.showRefund = (lg.showRefund ?? 0) + refund
                ev.append(seized ? .showSeized(refund: refund) : .showDropped(refund: refund))
            }
        }
        if keep.count < Rules.showMinBalloons {
            let refund = keep.count * Rules.showPerBalloon
            state.cash += refund
            if refund > 0 { lg.showRefund = (lg.showRefund ?? 0) + refund }
            state.local.showTonight = nil
            state.local.showIDs = nil
            state.local.showNext = nil
            state.local.showCount = max(0, (state.local.showCount ?? 1) - 1)
            ev.append(.showCancelled(refund: refund))
        }
    }
}
