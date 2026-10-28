import Foundation

/// v122: the tutorial that shows instead of tells (Faz 1). Progress only: which steps were done and on which day. The
/// app plays the steps (spotlight, arrow, one line) and records each one here, once; it sends the telemetry signal at
/// the same moment. Saves from before v122 that had already flown, or were past day one, skip it (`tutorialCheck`).
public struct TutorialState: Codable, Equatable, Sendable {
    /// Step → the day it was done. Steps: `price`, `price_low`, `go`, `burn`, `wind`, `vent`, `field`, `chimney`,
    /// `thermal`, `first_landing`, `skip`, and for the guided actions `ga_<lesson>_done` / `_left` / `_skip`.
    public var steps: [String: Int]
    /// The whole tutorial is over (every step done, skipped, or an old save).
    public var done: Bool?

    public init(steps: [String: Int] = [:], done: Bool? = nil) {
        self.steps = steps
        self.done = done
    }

    /// The steps that make up the tutorial (`TUT_ALL`); once all are done it is over.
    public static let all = ["price", "go", "price2", "burn", "wind", "vent", "field", "chimney", "thermal"]
    /// The flight's steps.
    public static let flightSteps = ["burn", "wind", "vent", "field", "chimney", "thermal"]
}

/// v122: the guide office's three guides (`GUIDES_PICK`). Sena (id mehmet) is the old single deal (v121): €1,500, +0.05
/// popularity, three days of five tourists, then five days to wait. Text: `guide.<rawValue>.name` / `.title`.
public enum GuideOffer: String, Codable, CaseIterable, Sendable {
    case ayse, mehmet, selin

    public var cost: Int { [900, 1500, 2400][index] }
    /// Popularity at once (×4 in stars).
    public var rep: Double { [0.03, 0.05, 0.07][index] }
    /// Days they send tourists, and how many a day.
    public var days: Int { [2, 3, 4][index] }
    public var pax: Int { [4, 5, 7][index] }
    /// Days to wait before the next guide flight.
    public var cooldown: Int { [4, 5, 6][index] }

    private var index: Int { Self.allCases.firstIndex(of: self) ?? 1 }
}

/// v122: the influencer agency's three influencers (`INFLU_PICK`). The travel influencer is the old single campaign.
/// Text: `influ.<rawValue>.name` / `.title`.
public enum InfluencerOffer: String, Codable, CaseIterable, Sendable {
    case local, travel, star

    /// Share of the campaign price (`Rules.influencerCost`), rounded to €100.
    public var priceFactor: Double { [0.6, 1, 1.8][index] }
    public var rep: Double { [0.06, 0.1, 0.16][index] }
    public var days: Int { [2, 3, 4][index] }
    public var pax: Int { [5, 8, 12][index] }
    public var cooldown: Int { [8, 10, 12][index] }

    /// `influPrice`.
    public func cost(_ s: GameState) -> Int { jsRound(Double(s.influencerCost) * priceFactor / 100) * 100 }

    private var index: Int { Self.allCases.firstIndex(of: self) ?? 1 }
}

extension GameState {
    /// The tutorial is running (not done, not skipped).
    public var tutorialOn: Bool { tutorial.map { $0.done != true } ?? false }
    public func tutorialHas(_ step: String) -> Bool { tutorial?.steps[step] != nil }

    /// v122.4: while the tutorial runs, days 1 and 2 in Cappadocia are a fixed scenario (`tutScene`): 1 or 2, else 0.
    public var tutorialScene: Int { region == .cap && tutorialOn && (day == 1 || day == 2) ? day : 0 }
}

/// v122.4 (`TUT_WX`, `TUT_DEMAND`, `TUT_P2`): the same first two days for everyone. Green flag, a layer that carries you
/// to the field, no request. Day 1: fewer tourists than seats at the start price, so lowering it fills seats. Day 2:
/// demand is high and the day starts at €160, so raising the price keeps the basket full (up to about €260).
public enum TutorialScene {
    public static let surfaceWind = [1: 5, 2: 6]
    public static let layers: [Int: [Double]] = [1: [-1.3, 4.6, -2.2, 6.2], 2: [-1, -2, 5.2, 3.4]]
    public static let target: [Int: Double] = [1: 1720, 2: 1900]
    public static let demand = [1: 110, 2: 320]
    public static let dayTwoPrice = 160
}

extension Game {
    /// `tutStep`: records a step once, with today's day. Returns true the first time (the app sends its telemetry
    /// signal then). Once every step of `TutorialState.all` is done the tutorial is over.
    @discardableResult
    public mutating func tutorialStep(_ step: String) -> Bool {
        var t = state.tutorial ?? TutorialState()
        guard t.steps[step] == nil else { return false }
        t.steps[step] = state.day
        if TutorialState.all.allSatisfy({ t.steps[$0] != nil }) { t.done = true }
        state.tutorial = t
        return true
    }

    /// "Geç": the whole tutorial ends. Returns true when it was running.
    @discardableResult
    public mutating func skipTutorial() -> Bool {
        guard state.tutorialOn else { return false }
        tutorialStep("skip")
        state.tutorial?.done = true
        return true
    }

    /// Saves from before v122: one that had flown or was past day one skips the tutorial.
    mutating func tutorialCheck() {
        guard state.tutorial == nil else { return }
        state.tutorial = (state.selfFlights ?? 0) >= 1 || state.day > 1 ? TutorialState(done: true) : TutorialState()
    }
}

extension FlightMoment {
    /// v122: the second own flight brings a thermal if the first had none, so the lesson isn't left to chance:
    /// 380–700 m ahead toward the landing field. `k` (0…1) picks where.
    public static func tutorialThermal(_ w: Weather, k: Double) -> FlightMoment {
        let dir: Double = w.target >= FlightWorld.launchX ? 1 : -1
        return FlightMoment(kind: .thermal, x: FlightWorld.launchX + dir * (380 + clamp(k, 0, 1) * 320))
    }
}
