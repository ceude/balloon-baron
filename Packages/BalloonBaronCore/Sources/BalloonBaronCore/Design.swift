import Foundation

/// Envelope patterns of the design studio. Names: `pattern.<rawValue>`.
public enum Pattern: String, Codable, CaseIterable, Sendable {
    case stripes, zigzag, checker, stars, hearts, sunburst, waves, rainbow, dots

    /// How eye-catching the pattern is on its own.
    public var flair: Int { [35, 60, 55, 70, 70, 75, 60, 65, 50][index] }
    private var index: Int { Self.allCases.firstIndex(of: self)! }
}

public struct Design: Codable, Identifiable, Equatable, Sendable {
    public let id: Int
    /// The player's name for it; empty means "<pattern> <number>".
    public var name: String
    public var number: Int
    public var pattern: Pattern
    /// Main, pattern and accent color.
    public var colors: [String]
    public var day: Int
    /// Creativity, 5–100.
    public var score: Int
}

public enum Studio {
    public static let workshopCost = 75000
    public static let designCost = 5000
    public static let reskinCost = 1000
    public static let swatches = ["#ff5e3a", "#ffc23d", "#2b2350", "#14a39a", "#ff6fa8", "#5aa9e6",
                                  "#9b7be0", "#22a45d", "#e5432f", "#ffffff", "#1f1b2e", "#f3e08a"]
    /// Daily cap on the popularity designs add.
    public static let maxDailyRep = 0.012

    static func luminance(_ hex: String) -> Double {
        let h = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
        guard h.count == 6, let v = UInt32(h, radix: 16) else { return 0 }
        let r = Double(v >> 16 & 0xff), g = Double(v >> 8 & 0xff), b = Double(v & 0xff)
        return (0.299 * r + 0.587 * g + 0.114 * b) / 255
    }
}

extension Game {
    public var designCost: Int { state.holding.has(.tyo) ? 0 : Studio.designCost }

    /// New designs are the talk of the town; after 40 days (60 with a Tokyo office) only 20% of the buzz is left.
    public func freshness(_ d: Design) -> Double {
        clamp(1 - Double(state.day - d.day) / (state.holding.has(.tyo) ? 60 : 40), 0.2, 1)
    }

    /// Contrast and variety score; repeating yourself or copying a rival's color costs points.
    public func designScore(pattern: Pattern, colors: [String], excluding id: Int? = nil) -> Int {
        let contrast = abs(Studio.luminance(colors[0]) - Studio.luminance(colors[1]))
        var s = Double(pattern.flair) * 0.6 + contrast * 30 + Double(Set(colors).count - 1) * 6 + 10
        if state.designs.contains(where: { $0.id != id && $0.pattern == pattern && $0.colors.first == colors[0] }) { s -= 20 }
        if state.rivals.contains(where: { $0.alive && $0.colors.first == colors[0] }) { s -= 10 }
        if state.holding.has(.tyo) { s += 10 }
        return clamp(jsRound(s), 5, 100)
    }

    @discardableResult
    public mutating func buildWorkshop() -> Bool {
        guard state.workshopDay == nil, state.cash >= Studio.workshopCost else { return false }
        state.cash -= Studio.workshopCost
        state.workshopDay = state.day
        return true
    }

    /// Paid from the region you're playing. Returns the new design's id.
    @discardableResult
    public mutating func createDesign(name: String, pattern: Pattern, colors: [String]) -> Int? {
        let cost = designCost
        guard state.workshopDay != nil, colors.count == 3, state.cash >= cost else { return nil }
        state.cash -= cost
        let score = designScore(pattern: pattern, colors: colors)
        let d = Design(id: state.nextID, name: name.trimmingCharacters(in: .whitespacesAndNewlines), number: state.designs.count + 1,
                       pattern: pattern, colors: colors, day: state.day, score: score)
        state.nextID += 1
        state.designs.append(d)
        return d.id
    }

    /// Paint a balloon with a design, or nil for company colors.
    @discardableResult
    public mutating func paint(_ balloonID: Int, design: Int?) -> Bool {
        guard let i = state.balloons.firstIndex(where: { $0.id == balloonID }), state.balloons[i].design != design,
              state.cash >= Studio.reskinCost else { return false }
        state.cash -= Studio.reskinCost
        state.balloons[i].design = design
        return true
    }
}
