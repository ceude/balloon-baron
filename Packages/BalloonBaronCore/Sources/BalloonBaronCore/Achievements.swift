import Foundation

/// Each first is a postcard kept in the album, shared by all regions. Title and line: `ach.<rawValue>` / `ach.<rawValue>.d`.
public enum Achievement: String, Codable, CaseIterable, CodingKeyRepresentable, Sendable {
    case first, mission, perfect10, fleet5, fleet10, fleet20, hotel, hotelOwn, star45, pax1k, pax10k
    case winter, fest, rivalDown, boss, design, upgrade3, xl, baronCap, abq, baronAbq, lux, baronLux, world
}

/// The holding's own goals, written on the office whiteboard. All six make you World Baron. Text: `hgoal.<rawValue>`.
public enum HoldingGoal: String, CaseIterable, Sendable {
    case million, baronAbq, tv, celebrity, research, offices
}

/// What a region's rival boss says, once each. Text: `boss.<region>.<rawValue>`.
public enum BossLine: String, Codable, CaseIterable, Sendable {
    case hello, ch1, ch2, passed, hotel, poach, accident, deal, gone
}

extension GameState {
    public func earned(_ a: Achievement) -> Bool {
        let s = statistics
        switch a {
        case .first: return day >= 2
        case .mission: return s.missions >= 1
        case .perfect10: return s.perfectLandings >= 10
        case .fleet5: return local.balloons.count >= 5
        case .fleet10: return local.balloons.count >= 10
        case .fleet20: return local.balloons.count >= 20
        case .hotel: return local.hotelDeals.count + local.ownHotels.count >= 1
        case .hotelOwn: return !local.ownHotels.isEmpty
        case .star45: return stars >= 4.5
        case .pax1k: return s.passengers >= 1000
        case .pax10k: return s.passengers >= 10000
        case .winter: return local.nextWinter != nil
        case .fest: return (local.festivalCount ?? 0) > 0 || local.fiestaFlown > 0
        case .rivalDown: return local.rivals.contains { !$0.alive }
        case .boss: return (bossSaid ?? []).contains { $0.hasSuffix(".gone") }
        case .design: return !designs.isEmpty
        case .upgrade3: return topBuildingLevel >= 3
        case .xl: return local.balloons.contains { $0.size == .XL }
        case .baronCap: return barons[.cap] != nil
        case .abq: return owns(.abq)
        case .baronAbq: return barons[.abq] != nil
        case .lux: return owns(.lux)
        case .baronLux: return barons[.lux] != nil
        case .world: return holding.worldBaron != nil
        }
    }

    public func done(_ g: HoldingGoal) -> Bool {
        switch g {
        case .million: return holding.cash >= 1_000_000
        case .baronAbq: return barons[.abq] != nil
        case .tv: return (holding.tvCount ?? 0) >= 1
        case .celebrity: return holding.celebrity != nil
        case .research: return holding.research >= Holding.researchLevels.count
        case .offices: return holding.offices.count >= Office.allCases.count
        }
    }
}

extension Game {
    /// Checked every evening: new postcards wait to be shown.
    mutating func checkAchievements() {
        var got = state.postcards ?? [:], fresh = state.newPostcards ?? []
        for a in Achievement.allCases where got[a] == nil && state.earned(a) {
            got[a] = state.day
            fresh.append(a)
        }
        state.postcards = got
        state.newPostcards = fresh
    }

    /// The next postcard to show, if any.
    public mutating func nextPostcard() -> Achievement? {
        guard var fresh = state.newPostcards, !fresh.isEmpty else { return nil }
        let a = fresh.removeFirst()
        state.newPostcards = fresh
        return a
    }

    mutating func checkHoldingGoals() {
        guard state.holding.worldBaron == nil, HoldingGoal.allCases.allSatisfy(state.done) else { return }
        state.holding.worldBaron = state.day
        state.hezQueue.append(.worldBaron)
        addPaper(.worldBaron)
    }

    /// Queue a boss line once per region, if that region has its boss's company in the market.
    mutating func bossSay(_ line: BossLine) {
        guard state.bossRival != nil else { return }
        let id = "\(state.region.rawValue).\(line.rawValue)"
        var said = state.bossSaid ?? []
        guard !said.contains(id) else { return }
        said.insert(id)
        state.bossSaid = said
        state.hezQueue.append(.boss(state.region, line))
    }

    func bossSaid(_ line: BossLine) -> Bool { (state.bossSaid ?? []).contains("\(state.region.rawValue).\(line.rawValue)") }

    /// After the chapter ceremony, when the next chapter starts: the boss notices you're growing.
    public mutating func chapterStarted(_ index: Int) {
        guard state.bossRival?.alive == true else { return }
        if index == 1 { bossSay(.ch1) } else if index == 2 { bossSay(.ch2) }
    }
}
