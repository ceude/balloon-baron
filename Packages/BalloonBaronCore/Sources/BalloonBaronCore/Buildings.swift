import Foundation

/// Town buildings you can upgrade twice. Names and level texts: `building.<rawValue>.*`.
public enum Building: String, Codable, CaseIterable, CodingKeyRepresentable, Sendable {
    /// Wind mast: tomorrow's forecast, then a radar that also sees the day after and softens yellow-flag risk.
    case mast
    /// Hangar: lower upkeep, then envelopes that wear more slowly.
    case hangar
    /// Pilot office: rivals poach half as often, then pilots learn 50% faster.
    case office
    /// Your ticket office: more tourists notice you.
    case mine

    public static let maxLevel = 3

    /// Cost of reaching `level` (2 or 3).
    public func cost(toLevel level: Int) -> Int? {
        let c: [Int] = switch self {
        case .mast: [6000, 25000]
        case .hangar: [12000, 45000]
        case .office: [10000, 35000]
        case .mine: [15000, 50000]
        }
        return (2...3).contains(level) ? c[level - 2] : nil
    }
}

/// A pilot's character. Name and description: `trait.<rawValue>` / `trait.<rawValue>.desc`.
public enum Trait: String, Codable, CaseIterable, Sendable {
    case showman, careful, daredevil, thrifty, loyal, storyteller, nightowl

    public var risk: Double { self == .careful ? 0.75 : self == .daredevil ? 1.3 : 1 }
    /// Badge color in the crew list.
    public var color: String {
        switch self {
        case .showman: "#ff6fa8"
        case .careful: "#22a45d"
        case .daredevil: "#e5432f"
        case .thrifty: "#14a39a"
        case .loyal: "#2b5ab8"
        case .storyteller: "#9b7be0"
        case .nightowl: "#6c6488"
        }
    }
}

extension GameState {
    /// A building's level, 1 to 3.
    public func level(_ b: Building) -> Int { local.buildings[b] ?? 1 }
    public var topBuildingLevel: Int { Building.allCases.map(level).max() ?? 1 }

    /// The flag rolled for `day`, when the wind mast can see it.
    public func forecastFlag(for day: Int) -> Flag? {
        let reach = level(.mast) >= 3 ? 2 : level(.mast) >= 2 ? 1 : 0
        guard day > self.day, day - self.day <= reach else { return nil }
        return local.forecast[day]
    }

    /// Daily upkeep multiplier from the hangar.
    var upkeepFactor: Double { [1, 1, 0.85, 0.7][level(.hangar)] }
    /// Demand multiplier from your ticket office.
    var officeDemand: Double { [1, 1, 1.05, 1.12][level(.mine)] }
}

extension Game {
    /// Next upgrade's cost, nil at the top level.
    public func upgradeCost(_ b: Building) -> Int? { b.cost(toLevel: state.level(b) + 1) }

    @discardableResult
    public mutating func upgrade(_ b: Building) -> Bool {
        let lv = state.level(b)
        guard let cost = b.cost(toLevel: lv + 1), state.cash >= cost else { return false }
        state.cash -= cost
        state.buildings[b] = lv + 1
        paperAdd(1, .upgrade(b, level: lv + 1))
        ensureForecast()
        return true
    }

    mutating func rollFlag() -> Flag {
        let r = rng.unit(), winter = state.winter != nil
        return r < (winter ? 0.35 : 0.55) ? .green : r < (winter ? 0.7 : 0.85) ? .yellow : .red
    }

    /// Rolls the next two days' flags ahead of time, so the mast's forecast is the weather you then get.
    mutating func ensureForecast() {
        var fc = state.local.forecast.filter { $0.key >= state.day }
        for d in [state.day + 1, state.day + 2] where fc[d] == nil { fc[d] = rollFlag() }
        state.local.forecast = fc
    }
}
