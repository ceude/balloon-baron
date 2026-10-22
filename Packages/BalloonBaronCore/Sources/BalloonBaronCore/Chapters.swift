import Foundation

/// What a chapter asks for. Labels: `goal.<rawValue>`.
public enum GoalKind: String, Codable, Sendable {
    case balloons, stars, cash, hotelDeal, hotelOwn, influencer, guide, share, workshop, school, xl, fiesta
    /// Building levels: the wind mast, the hangar, or any building.
    case bldMast, bldHangar, bldTop

    /// Shown as done / not yet instead of a count.
    public var yesNo: Bool { [.workshop, .school, .xl, .influencer, .guide, .fiesta, .bldMast, .bldHangar, .bldTop].contains(self) }
    var building: Bool { [.bldMast, .bldHangar, .bldTop].contains(self) }
}

public struct Goal: Equatable, Sendable {
    public let kind: GoalKind
    public let target: Double
}

/// A step towards becoming a region's baron. Name and award text: `chapter.<id>` / `chapter.<id>.award`.
public struct Chapter: Equatable, Sendable {
    public let id: String
    public let reward: Int
    public let goals: [Goal]

    static func all(in r: RegionID) -> [Chapter] {
        func g(_ k: GoalKind, _ t: Double) -> Goal { Goal(kind: k, target: t) }
        switch r {
        case .cap:
            return [
                Chapter(id: "founding", reward: 5000, goals: [g(.balloons, 5), g(.stars, 4.0), g(.hotelDeal, 1), g(.cash, 20000), g(.bldMast, 2)]),
                Chapter(id: "growth", reward: 20000, goals: [g(.balloons, 10), g(.hotelOwn, 1), g(.influencer, 1), g(.guide, 1), g(.share, 0.5), g(.workshop, 1),
                                                             g(.bldHangar, 2)]),
                Chapter(id: "baron", reward: 0, goals: [g(.share, 0.7), g(.hotelOwn, 2), g(.school, 1), g(.stars, 4.8), g(.xl, 1), g(.bldTop, 3)])
            ]
        case .abq:
            return [
                Chapter(id: "newWorld", reward: 5000, goals: [g(.balloons, 5), g(.stars, 4.0), g(.hotelDeal, 1), g(.guide, 1), g(.bldMast, 2)]),
                Chapter(id: "fiesta", reward: 20000, goals: [g(.balloons, 10), g(.hotelOwn, 1), g(.fiesta, 1), g(.influencer, 1), g(.share, 0.5), g(.bldHangar, 2)]),
                Chapter(id: "baronAbq", reward: 0, goals: [g(.share, 0.7), g(.hotelOwn, 2), g(.school, 1), g(.stars, 4.8), g(.xl, 1), g(.bldTop, 3)])
            ]
        }
    }
}

extension GameState {
    /// The chapter you're working on, nil once you're the region's baron.
    public var currentChapter: Chapter? {
        let cs = region.chapters
        return cs.indices.contains(local.chapter) ? cs[local.chapter] : nil
    }

    public func value(_ k: GoalKind) -> Double {
        let s = local
        switch k {
        case .balloons: return Double(s.balloons.count)
        case .stars: return stars
        case .cash: return Double(s.cash)
        case .hotelDeal: return Double(s.hotelDeals.count)
        case .hotelOwn: return Double(s.ownHotels.count)
        case .influencer: return Double(s.influencerCount)
        case .guide: return Double(s.guideCount)
        case .share: return s.shareNow
        case .workshop: return workshopDay != nil ? 1 : 0
        case .school: return s.school ? 1 : 0
        case .xl: return s.balloons.contains { $0.size == .XL } ? 1 : 0
        case .fiesta: return Double(s.fiestaFlown)
        case .bldMast: return Double(level(.mast))
        case .bldHangar: return Double(level(.hangar))
        case .bldTop: return Double(topBuildingLevel)
        }
    }

    public func done(_ g: Goal) -> Bool { value(g.kind) >= g.target - 1e-9 }
    /// Buildings start at level 1, so their bar counts the levels still to build.
    public func progress(_ g: Goal) -> Double {
        g.kind.building ? clamp((value(g.kind) - 1) / (g.target - 1), 0, 1) : clamp(value(g.kind) / g.target, 0, 1)
    }
}

extension Game {
    /// Pays the reward when every goal of the current chapter is met. Returns the reward.
    mutating func checkChapters(events ev: inout [DayEvent]) -> Int {
        guard let c = state.currentChapter, c.goals.allSatisfy(state.done) else { return 0 }
        let r = state.region
        state.chapterNews = ChapterNews(region: r, index: state.chapter)
        state.chapter += 1
        if state.chapter >= r.chapters.count {
            state.barons[r] = state.day
            if r == .cap { state.hezQueue.append(.holdingOpened) }
            ev.append(.baron(r))
        } else {
            ev.append(.chapterDone(c.id, reward: c.reward))
        }
        state.cash += c.reward
        return c.reward
    }
}
