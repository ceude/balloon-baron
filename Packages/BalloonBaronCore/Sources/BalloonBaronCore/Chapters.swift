import Foundation

/// What a chapter asks for. Labels: `goal.<rawValue>`.
public enum GoalKind: String, Codable, Sendable {
    case balloons, pilots, stars, cash, hotelDeal, hotelOwn, influencer, guide, share, workshop, school, xl, fiesta
    /// v114: a balloon built in your own workshop (level 2).
    case factoryBuilt
    /// v124.6: seats in the fleet (S 8, M 16, L 24, XL 32), so every balloon size counts fairly.
    case seats
    /// v124 Bristol: an own flight ended safely on a foggy morning; a Night Glow held.
    case fog, glow
    /// Building levels: the wind mast, the hangar, or any building.
    case bldMast, bldHangar, bldTop

    /// Shown as done / not yet instead of a count.
    public var yesNo: Bool { [.workshop, .factoryBuilt, .school, .xl, .influencer, .guide, .fiesta, .fog, .glow, .bldMast, .bldHangar, .bldTop].contains(self) }
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
                Chapter(id: "founding", reward: 5000, goals: [g(.seats, 16), g(.pilots, 1), g(.stars, 4.3), g(.hotelDeal, 1), g(.bldMast, 2)]),
                Chapter(id: "rising", reward: 10000, goals: [g(.seats, 64), g(.influencer, 1), g(.guide, 1), g(.bldHangar, 2)]),
                Chapter(id: "growth", reward: 20000, goals: [g(.seats, 150), g(.hotelOwn, 1), g(.share, 0.5), g(.factoryBuilt, 1)]),
                Chapter(id: "baron", reward: 0, goals: [g(.share, 0.7), g(.hotelOwn, 2), g(.school, 1), g(.stars, 4.8), g(.xl, 1), g(.bldTop, 3)])
            ]
        case .abq:
            return [
                Chapter(id: "newWorld", reward: 5000, goals: [g(.seats, 32), g(.pilots, 2), g(.stars, 4.6), g(.hotelDeal, 2), g(.guide, 1), g(.bldMast, 2)]),
                Chapter(id: "boxWind", reward: 10000, goals: [g(.seats, 100), g(.influencer, 1), g(.stars, 4.7), g(.bldMast, 3), g(.bldHangar, 2)]),
                Chapter(id: "fiesta", reward: 20000, goals: [g(.seats, 180), g(.hotelOwn, 1), g(.fiesta, 1), g(.share, 0.5)]),
                Chapter(id: "baronAbq", reward: 0, goals: [g(.share, 0.7), g(.hotelOwn, 2), g(.school, 1), g(.stars, 4.8), g(.xl, 1), g(.bldHangar, 3)])
            ]
        case .lux:
            return [
                Chapter(id: "westBank", reward: 5000, goals: [g(.seats, 48), g(.pilots, 3), g(.stars, 4.7), g(.hotelDeal, 2), g(.guide, 1), g(.bldMast, 2)]),
                Chapter(id: "nileWind", reward: 10000, goals: [g(.seats, 120), g(.influencer, 1), g(.stars, 4.75), g(.share, 0.3), g(.bldMast, 3), g(.bldHangar, 2)]),
                Chapter(id: "pharaohs", reward: 20000, goals: [g(.seats, 220), g(.hotelOwn, 1), g(.fiesta, 1), g(.share, 0.5)]),
                Chapter(id: "baronLux", reward: 0, goals: [g(.share, 0.7), g(.hotelOwn, 2), g(.school, 1), g(.stars, 4.8), g(.xl, 1), g(.bldHangar, 3)])
            ]
        // v124: a step harder than Luxor (balanced with tools/sim-campaign.js); the gorge wants a foggy flight, the
        // festival a Night Glow.
        case .bri:
            return [
                Chapter(id: "ashton", reward: 5000, goals: [g(.seats, 48), g(.pilots, 3), g(.stars, 4.7), g(.hotelDeal, 2), g(.guide, 1), g(.bldMast, 2)]),
                Chapter(id: "avonGorge", reward: 10000, goals: [g(.seats, 220), g(.influencer, 1), g(.stars, 4.75), g(.share, 0.35), g(.fog, 1), g(.bldMast, 3), g(.bldHangar, 2)]),
                Chapter(id: "festivalBri", reward: 20000, goals: [g(.seats, 380), g(.hotelOwn, 1), g(.fiesta, 1), g(.glow, 1), g(.share, 0.55)]),
                Chapter(id: "baronBri", reward: 0, goals: [g(.share, 0.75), g(.hotelOwn, 2), g(.school, 1), g(.stars, 4.8), g(.xl, 1), g(.bldHangar, 3)])
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
        case .seats: return Double(s.balloons.reduce(0) { $0 + $1.size.capacity })
        case .pilots: return Double(s.pilots.count)
        case .stars: return stars
        case .cash: return Double(s.cash)
        case .hotelDeal: return Double(s.hotelDeals.count)
        case .hotelOwn: return Double(s.ownHotels.count)
        case .influencer: return Double(s.influencerCount)
        case .guide: return Double(s.guideCount)
        case .share: return s.shareNow
        case .workshop: return workshopDay != nil ? 1 : 0
        case .factoryBuilt: return Double(factory?.made ?? 0)
        case .school: return s.school ? 1 : 0
        case .xl: return s.balloons.contains { $0.size == .XL } ? 1 : 0
        case .fiesta: return Double(s.fiestaFlown)
        case .fog: return Double(s.fogFlown ?? 0)
        case .glow: return Double(s.glowCount ?? 0)
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

extension Game {
    /// A chapter is finished the moment its goals are met, not only at the end of the day; the baron's
    /// chapter too (v109): all its goals holding at once is enough.
    @discardableResult
    public mutating func finishChapterNow() -> Bool {
        guard state.chapterNews == nil, state.chapter < state.region.chapters.count else { return false }
        var ev: [DayEvent] = []
        _ = checkChapters(events: &ev)
        return state.chapterNews != nil
    }
}

extension GameState {
    /// Brings an older save up to date. Version 3 had three chapters per region; a new second chapter was added,
    /// so anyone past it skips ahead and nobody falls back.
    mutating func migrate() {
        // v124.4: Cappadocia's pilots and candidates had Q, W and X initials too
        func fix(_ l: inout [Pilot]) {
            for i in l.indices {
                let n = l[i].name
                guard n.count >= 3, n.hasSuffix("."), let c = n.dropLast().last, n.dropLast(2).last == " ",
                      let r = ["Q": "K", "W": "V", "X": "S"][String(c)] else { continue }
                l[i].name = String(n.dropLast(2)) + r + "."
            }
        }
        if region == .cap { fix(&local.pilots); fix(&local.candidates) }
        else if parked[.cap] != nil { fix(&parked[.cap]!.state.pilots); fix(&parked[.cap]!.state.candidates) }
        guard version < 4 else { return }
        func shift(_ c: Int) -> Int { c >= 2 ? c + 1 : c }
        local.chapter = shift(local.chapter)
        for id in parked.keys { if let c = parked[id]?.state.chapter { parked[id]?.state.chapter = shift(c) } }
        if let n = chapterNews, n.index >= 1 { chapterNews?.index = n.index + 1 }
        version = 4
    }
}
