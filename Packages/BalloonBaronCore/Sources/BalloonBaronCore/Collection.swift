import Foundation

/// Running totals across the whole company, for achievements.
public struct Stats: Codable, Equatable, Sendable {
    public var perfectLandings = 0
    public var missions = 0
    public var passengers = 0
    public var winters = 0
}

/// A first worth a postcard in the album. Title and line: `ach.<rawValue>` / `ach.<rawValue>.desc`.
public enum Achievement: String, Codable, CaseIterable, CodingKeyRepresentable, Sendable {
    case first, mission, perfect10, fleet5, fleet10, fleet20, hotel, hotelOwn, star45, pax1k, pax10k
    case winter, fest, rivalDown, boss, design, upgrade3, xl, baronCap, abq, baronAbq, world

    func earned(_ s: GameState) -> Bool {
        let l = s.local
        switch self {
        case .first: return s.day >= 2
        case .mission: return s.stats.missions >= 1
        case .perfect10: return s.stats.perfectLandings >= 10
        case .fleet5: return l.balloons.count >= 5
        case .fleet10: return l.balloons.count >= 10
        case .fleet20: return l.balloons.count >= 20
        case .hotel: return l.hotelDeals.count + l.ownHotels.count >= 1
        case .hotelOwn: return !l.ownHotels.isEmpty
        case .star45: return s.stars >= 4.5
        case .pax1k: return s.stats.passengers >= 1000
        case .pax10k: return s.stats.passengers >= 10000
        case .winter: return s.stats.winters >= 1
        case .fest: return l.festivalCount > 0 || l.fiestaFlown > 0
        case .rivalDown: return l.rivals.contains { !$0.alive }
        case .boss: return s.bossSaid.contains { $0.hasSuffix(".gone") }
        case .design: return !s.designs.isEmpty
        case .upgrade3: return s.topBuildingLevel >= 3
        case .xl: return l.balloons.contains { $0.size == .XL }
        case .baronCap: return s.barons[.cap] != nil
        case .abq: return s.owns(.abq)
        case .baronAbq: return s.barons[.abq] != nil
        case .world: return s.worldBaron != nil
        }
    }
}

/// The holding's big goals, written on the office whiteboard. Text: `holdGoal.<rawValue>`.
public enum HoldGoal: String, CaseIterable, Sendable {
    case million, baronAbq, tv, celebrity, research, offices

    public func done(_ s: GameState) -> Bool {
        switch self {
        case .million: return s.holding.cash >= 1_000_000
        case .baronAbq: return s.barons[.abq] != nil
        case .tv: return s.holding.tvCount >= 1
        case .celebrity: return s.holding.celebrity != nil
        case .research: return s.holding.research >= Holding.researchLevels.count
        case .offices: return s.holding.offices.count >= Office.allCases.count
        }
    }
}

extension Game {
    /// Checked every evening: new firsts become postcards to show the next morning.
    mutating func checkAchievements() {
        for a in Achievement.allCases where state.achievements[a] == nil && a.earned(state) {
            state.achievements[a] = state.day
            state.newPostcards.append(a)
        }
    }

    /// Every holding goal done: the company becomes a World Baron.
    mutating func checkHoldGoals() {
        guard state.anyBaron, state.worldBaron == nil, HoldGoal.allCases.allSatisfy({ $0.done(state) }) else { return }
        state.worldBaron = state.day
        state.hezQueue.append(.worldBaron)
        paperAdd(6, .worldBaron)
        checkAchievements()
    }

    /// Takes the next postcard to show.
    public mutating func nextPostcard() -> Achievement? {
        state.newPostcards.isEmpty ? nil : state.newPostcards.removeFirst()
    }
}
