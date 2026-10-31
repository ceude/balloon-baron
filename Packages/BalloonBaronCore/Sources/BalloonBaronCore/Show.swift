import Foundation

/// v111: the Balloon Show (`showCard`, `bookShow`). Every balloon that can fly lights up over the town one night:
/// paid per balloon, all of them or none, once every `Rules.showCooldown` days from `Rules.showMinBalloons` balloons.
public enum ShowState: Equatable, Sendable {
    case locked, booked, few, cash, ok
    case wait(days: Int)
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
}
