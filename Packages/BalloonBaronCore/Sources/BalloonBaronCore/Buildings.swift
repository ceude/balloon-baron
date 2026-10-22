import Foundation

/// Four buildings grow in three levels, per region. Names: `building.<rawValue>`; levels: `building.<rawValue>.<level>`.
public enum Building: String, Codable, CaseIterable, CodingKeyRepresentable, Sendable {
    /// Wind mast: 2 shows tomorrow's flag, 3 the day after too and cuts yellow-flag accidents by 20%.
    case mast
    /// Hangar: 2 cuts upkeep 15%, 3 cuts it 30% and envelopes wear 15% slower.
    case hangar
    /// Pilot office: 2 halves rivals' poaching, 3 gives pilots 50% more experience per flight.
    case office
    /// Your booking office: 2 brings 5% more tourists, 3 brings 12% more.
    case sales

    public static let maxLevel = 3

    /// Cost of going from `level` to the next one, nil at the top.
    public func upgradeCost(from level: Int) -> Int? {
        let costs: [Int] = switch self {
        case .mast: [6000, 25000]
        case .hangar: [12000, 45000]
        case .office: [10000, 35000]
        case .sales: [15000, 50000]
        }
        return (1...2).contains(level) ? costs[level - 1] : nil
    }
}

extension GameState {
    public func level(_ b: Building) -> Int { local.level(b) }
    /// Highest level of any building in the region.
    public var topBuildingLevel: Int { Building.allCases.map(level).max() ?? 1 }
    public var upkeepFactor: Double { [1, 1, 0.85, 0.7][level(.hangar)] }
    public var salesFactor: Double { [1, 1, 1.05, 1.12][level(.sales)] }
}

extension Game {
    @discardableResult
    public mutating func upgrade(_ b: Building) -> Bool {
        let n = state.level(b)
        guard let cost = b.upgradeCost(from: n), state.cash >= cost else { return false }
        state.cash -= cost
        var lv = state.buildings ?? [:]
        lv[b] = n + 1
        state.buildings = lv
        addPaper(.upgrade(b, level: n + 1))
        return true
    }

    /// A day's flag, rolled from the season's odds.
    mutating func rollFlag() -> Flag {
        let r = rng.unit(), winter = state.winter != nil
        return r < (winter ? 0.35 : 0.55) ? .green : r < (winter ? 0.7 : 0.85) ? .yellow : .red
    }

    /// The flag a coming day will have, rolled now and kept, so the forecast comes true.
    public mutating func forecastFlag(_ day: Int) -> Flag {
        var fc = (state.forecast ?? [:]).filter { $0.key >= state.day }
        let f = fc[day] ?? rollFlag()
        fc[day] = f
        state.forecast = fc
        return f
    }

    /// What the wind mast shows: tomorrow from level 2, the day after as well from level 3.
    public mutating func forecast() -> [Flag] {
        let n = state.level(.mast)
        return n < 2 ? [] : (1..<n).map { forecastFlag(state.day + $0) }
    }
}
