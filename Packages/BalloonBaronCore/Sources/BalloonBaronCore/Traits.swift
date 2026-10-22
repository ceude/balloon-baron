import Foundation

/// A pilot's character: most candidates come with one. Name and effect: `trait.<rawValue>` / `trait.<rawValue>.d`.
public enum PilotTrait: String, Codable, CaseIterable, Sendable {
    /// Tips three times as big.
    case showman
    /// 25% fewer accidents.
    case careful
    /// 30% more accidents, but every flight adds popularity.
    case daredevil
    /// 15% less fuel.
    case thrifty
    /// Rivals' offers don't interest them.
    case loyal
    /// Popularity on every flight and now and then a glowing review.
    case storyteller
    /// 15% lower wage, but sometimes oversleeps.
    case nightOwl

    /// How the trait scales the pilot's accident risk.
    public var accidentFactor: Double { self == .careful ? 0.75 : self == .daredevil ? 1.3 : 1 }

    public var color: String {
        ["#ff6fa8", "#22a45d", "#e5432f", "#14a39a", "#2b5ab8", "#9b7be0", "#6c6488"][Self.allCases.firstIndex(of: self)!]
    }
}

extension Game {
    /// A quarter of candidates have no particular trait.
    mutating func rollTrait() -> PilotTrait? { rng.chance(0.25) ? nil : rng.pick(PilotTrait.allCases) }

    /// The pilot's own accident multiplier: level times trait, as `accidentChance` uses it.
    public static func pilotRisk(_ p: Pilot) -> Double { p.level.risk * (p.trait?.accidentFactor ?? 1) }

    /// The trait of whoever flies this balloon, unless that's you.
    func trait(of b: Balloon) -> PilotTrait? { state.isSelf(b) ? nil : state.pilot(of: b)?.trait }

    /// Once a day, a night owl flying today may oversleep (7%).
    mutating func rollLatePilot() {
        guard state.lateChecked != state.day else { return }
        state.lateChecked = state.day
        let owls = state.pilots.filter { p in p.trait == .nightOwl && state.balloons.contains { $0.pilot == p.id } }
        if !owls.isEmpty && rng.chance(0.07) { state.late = LatePilot(day: state.day, pilot: rng.pick(owls).id) }
    }
}
