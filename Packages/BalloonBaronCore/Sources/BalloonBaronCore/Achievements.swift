import Foundation

/// Each first is a postcard kept in the album, shared by all regions. Title and line: `ach.<rawValue>` / `ach.<rawValue>.d`.
public enum Achievement: String, Codable, CaseIterable, CodingKeyRepresentable, Sendable {
    case first, mission, perfect10, fleet5, fleet10, fleet20, hotel, hotelOwn, star45, pax1k, pax10k
    case winter, fest, rivalDown, boss, design, upgrade3, xl, baronCap, abq, baronAbq, lux, baronLux
    /// v124: entering Bristol, the first Night Glow, Baron of Bristol.
    case bri, nightGlow, baronBri
    case world
    /// v140: the Hot Air Foundation's first project.
    case patron
    /// v141: entering the Maasai Mara, Baron of the Maasai Mara.
    case mara, baronMara

    /// v141.1: Game Center points (`balloonbaron.ach.<rawValue>` in App Store Connect; docs/APP_STORE.md). Apple allows
    /// 1000 in all; `gameCenterReserve` is kept free for a future Asian region's two postcards.
    public var gameCenterPoints: Int {
        switch self {
        case .first: 5
        case .mission: 10
        case .perfect10: 25
        case .fleet5: 10
        case .fleet10: 20
        case .fleet20: 35
        case .hotel: 10
        case .hotelOwn: 25
        case .star45: 30
        case .pax1k: 15
        case .pax10k: 35
        case .winter: 15
        case .fest: 10
        case .rivalDown: 25
        case .boss: 35
        case .design: 10
        case .upgrade3: 25
        case .xl: 40
        case .baronCap: 50
        case .abq: 20
        case .baronAbq: 50
        case .lux: 20
        case .baronLux: 60
        case .bri: 20
        case .nightGlow: 15
        case .baronBri: 60
        case .world: 100
        case .patron: 15
        case .mara: 20
        case .baronMara: 70
        }
    }
    /// Points kept free for a future region's entry and baron postcards (Apple's limit is 1000).
    public static let gameCenterReserve = 120
    public static let gameCenterLimit = 1000
}

/// The holding's own goals, written on the office whiteboard. All seven make you World Baron. Text: `hgoal.<rawValue>`.
/// v137: listed in the order the campaign simulator meets them on average (`tools/sim-campaign.js`, 32 seeds: million
/// 219, Luxor 441, TV 442, celebrity 444, six offices 446, all four R&D levels 520, World Games 631). v141: the offices
/// open with their regions (Dubai needs the Maasai Mara), so six offices come after R&D (8 seeds: R&D 497, offices 565).
public enum HoldingGoal: String, CaseIterable, Sendable {
    /// v141.2 (developer): the TV campaign goal gave way to the Maasai Mara's first safari-plane group (`maraGroup`).
    /// Still in the simulator's order (24 seeds): million 220, Luxor 436, celebrity 438, R&D 509, six offices 570, World
    /// Games 631, the Mara's first group 646 (World Baron 631 → 657).
    case million, baronLux, celebrity, research, offices
    /// v123.5: the World Games show (it needs the Baron of Bristol).
    case worldGames
    case maraGroup
}

/// What a region's rival boss says, once each. Text: `boss.<region>.<rawValue>`.
public enum BossLine: String, Codable, CaseIterable, Sendable {
    case hello, ch1, ch2, passed, hotel, poach, accident, deal, gone
}

extension GameState {
    public func earned(_ a: Achievement) -> Bool {
        let s = statistics
        switch a {
        case .first: return firstCleanFlight == true
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
        case .fest: return local.festivalFlown == true || local.fiestaFlown > 0
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
        case .bri: return owns(.bri)
        case .nightGlow: return (local.glowCount ?? 0) >= 1
        case .baronBri: return barons[.bri] != nil
        case .mara: return owns(.mara)
        case .baronMara: return barons[.mara] != nil
        case .world: return holding.worldBaron != nil
        case .patron: return holding.projects >= 1
        }
    }

    /// v141.2: safari-plane groups flown in full in the Maasai Mara, whether you're there or it runs on autopilot.
    public var maraGroups: Int {
        (region == .mara ? local.contracts : parked[.mara]?.state.contracts)?.ok ?? 0
    }

    /// Once you're World Baron the goals stay ticked, whatever the holding's cash does later.
    public func done(_ g: HoldingGoal) -> Bool {
        holding.worldBaron != nil || met(g)
    }

    /// The goal as it stands today, whatever the title says. v137: six offices and all four R&D levels.
    public func met(_ g: HoldingGoal) -> Bool {
        switch g {
        case .million: return holding.millionOn != nil || holding.cash >= Holding.millionGoal
        case .baronLux: return barons[.lux] != nil
        case .maraGroup: return maraGroups >= 1
        case .celebrity: return holding.celebrity != nil
        case .research: return holding.research >= Holding.researchLevels.count
        case .offices: return holding.offices.count >= Office.allCases.count
        case .worldGames: return holding.worldGamesUntil != nil
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

    /// The company's round days get a word from the guide and a story in the morning paper.
    public static let milestones = [100, 200, 300, 365, 400, 500]
    mutating func milestoneCheck() {
        let d = state.day
        guard Self.milestones.contains(d) || (d > 500 && d % 100 == 0) else { return }
        state.hezQueue.append(.milestone(d))
        addPaper(.milestone(d))
    }

    /// v132: the €1 million goal is met the moment the holding's cash reaches it, and stays met.
    mutating func markMillion() {
        if state.holding.millionOn == nil && state.holding.cash >= Holding.millionGoal { state.holding.millionOn = state.day }
    }

    /// v132: the holding goals are checked wherever the holding's cash can rise (a transfer by hand, the day's autopilot
    /// income), not only at the end of the day; the app also calls this after every action.
    public mutating func holdingGoalsNow() {
        markMillion()
        if state.anyBaron { checkHoldingGoals() }
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
