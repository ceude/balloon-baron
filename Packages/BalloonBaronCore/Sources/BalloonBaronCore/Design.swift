import Foundation

/// Envelope patterns of the design studio. Names: `pattern.<rawValue>`.
public enum Pattern: String, Codable, CaseIterable, Sendable {
    case stripes, zigzag, checker, stars, hearts, sunburst, waves, rainbow, dots
    /// Bought in the bazaar: higher flair, and designs using them never fade.
    case gold, tile, sky, kilim

    /// How eye-catching the pattern is on its own.
    public var flair: Int { [35, 60, 55, 70, 70, 75, 60, 65, 50, 92, 90, 92, 90][index] }
    public var premium: Bool { index >= 9 }
    public var storeItem: StoreItem? { premium ? StoreItem(rawValue: rawValue) : nil }
    private var index: Int { Self.allCases.firstIndex(of: self)! }
}

/// Shaped envelopes from the bazaar; they turn heads (+8 creativity, a little popularity every flight).
public enum EnvelopeShape: String, Codable, CaseIterable, Sendable {
    case heart, star, skull
    /// The skull replaced the Hezarfen balloon; saves that had it read as the skull.
    public init?(rawValue: String) {
        switch rawValue {
        case "heart": self = .heart
        case "star": self = .star
        case "skull", "hezarfen": self = .skull
        default: return nil
        }
    }
    public var storeItem: StoreItem { StoreItem(rawValue: rawValue)! }
}

/// Everything sold for real money, in the bazaar. Names: `store.<rawValue>`. StoreKit 2 non-consumables:
/// patterns and decorations tier 1, shapes tier 2. The lantern strings are Hezarfen's free gift.
public enum StoreItem: String, Codable, CaseIterable, CodingKeyRepresentable, Sendable {
    case gold, tile, sky, kilim
    case heart, star, skull
    case fountain, statue, lanterns, flags

    /// The skull replaced the Hezarfen balloon: whoever bought that one owns the skull.
    public init?(rawValue: String) {
        guard let k = Self.allCases.first(where: { "\($0)" == (rawValue == "hezarfen" ? "skull" : rawValue) }) else { return nil }
        self = k
    }

    public enum Kind: Sendable { case pattern, shape, decoration }
    public var kind: Kind {
        switch self {
        case .gold, .tile, .sky, .kilim: .pattern
        case .heart, .star, .skull: .shape
        case .fountain, .statue, .lanterns, .flags: .decoration
        }
    }
    public var gift: Bool { self == .lanterns }
    /// App Store price tier.
    public var tier: Int { kind == .shape ? 2 : 1 }
    public var productID: String { "balloonbaron.\(rawValue)" }
    public var pattern: Pattern? { kind == .pattern ? Pattern(rawValue: rawValue) : nil }
    public var shape: EnvelopeShape? { kind == .shape ? EnvelopeShape(rawValue: rawValue) : nil }
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
    // Added in version 3.
    public var shape: EnvelopeShape?
    /// Set when the design came ready-made from the bazaar; it is named after the item.
    public var gift: StoreItem?

    /// Uses something bought with real money: it never fades and goes on any balloon for free.
    public var paid: Bool { shape != nil || pattern.premium }

    /// A design that isn't saved, for drawing a preview (the studio's 3D balloon).
    public init(preview pattern: Pattern, colors: [String], shape: EnvelopeShape? = nil) {
        self.init(id: 0, name: "", number: 0, pattern: pattern, colors: colors, day: 0, score: 0, shape: shape, gift: nil)
    }

    init(id: Int, name: String, number: Int, pattern: Pattern, colors: [String], day: Int, score: Int, shape: EnvelopeShape? = nil, gift: StoreItem? = nil) {
        self.id = id; self.name = name; self.number = number; self.pattern = pattern; self.colors = colors
        self.day = day; self.score = score; self.shape = shape; self.gift = gift
    }
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
        if d.paid { return 1 }
        return clamp(1 - Double(state.day - d.day) / (state.holding.has(.tyo) ? 60 : 40), 0.2, 1)
    }

    /// Contrast and variety score; repeating yourself or copying a rival's color costs points.
    public func designScore(pattern: Pattern, colors: [String], shape: EnvelopeShape? = nil, excluding id: Int? = nil) -> Int {
        let contrast = abs(Studio.luminance(colors[0]) - Studio.luminance(colors[1]))
        var s = Double(pattern.flair) * 0.6 + contrast * 30 + Double(Set(colors).count - 1) * 6 + 10
        if state.designs.contains(where: { $0.id != id && $0.pattern == pattern && $0.colors.first == colors[0] }) { s -= 20 }
        if state.rivals.contains(where: { $0.alive && $0.colors.first == colors[0] }) { s -= 10 }
        if state.holding.has(.tyo) { s += 10 }
        if shape != nil { s += 8 }
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
    public mutating func createDesign(name: String, pattern: Pattern, colors: [String], shape: EnvelopeShape? = nil) -> Int? {
        let cost = designCost
        guard state.workshopDay != nil, colors.count == 3, state.cash >= cost,
              pattern.storeItem.map(state.owned) ?? true, shape.map({ state.owned($0.storeItem) }) ?? true else { return nil }
        state.cash -= cost
        let score = designScore(pattern: pattern, colors: colors, shape: shape)
        let d = Design(id: state.nextID, name: name.trimmingCharacters(in: .whitespacesAndNewlines), number: state.designs.count + 1,
                       pattern: pattern, colors: colors, day: state.day, score: score, shape: shape)
        state.nextID += 1
        state.designs.append(d)
        return d.id
    }

    /// Repainting costs `Studio.reskinCost`; designs from the bazaar go on for free.
    public func paintCost(_ design: Int?) -> Int {
        design.flatMap { id in state.designs.first { $0.id == id } }?.paid == true ? 0 : Studio.reskinCost
    }

    /// Paint a balloon with a design, or nil for company colors.
    @discardableResult
    public mutating func paint(_ balloonID: Int, design: Int?) -> Bool {
        let cost = paintCost(design)
        guard let i = state.balloons.firstIndex(where: { $0.id == balloonID }), state.balloons[i].design != design,
              state.cash >= cost else { return false }
        state.cash -= cost
        state.balloons[i].design = design
        return true
    }
}

extension Game {
    /// A store purchase went through (or the free gift was taken). A pattern or shape arrives as a ready
    /// design in company colors and goes straight onto the flagship, so it works without the workshop.
    public mutating func grantStoreItem(_ k: StoreItem) {
        guard !state.owned(k) else { return }
        var st = state.store ?? [:]
        st[k] = state.day
        state.store = st
        guard k.kind != .decoration else { return }
        let c = state.colors
        let pattern = k.pattern ?? .stripes, colors = [c[0], c.count > 1 ? c[1] : "#ffffff", "#ffffff"]
        var d = Design(id: state.nextID, name: "", number: state.designs.count + 1, pattern: pattern, colors: colors,
                       day: state.day, score: 0, shape: k.shape, gift: k)
        d.score = designScore(pattern: pattern, colors: colors, shape: k.shape)
        state.nextID += 1
        state.designs.append(d)
        let fb = state.balloon(state.flagship) ?? state.balloons.first
        if let fb, let i = state.balloons.firstIndex(where: { $0.id == fb.id }) { state.balloons[i].design = d.id }
        state.hezQueue.insert(.bazaarGift(k, balloon: fb?.name), at: 0)
    }
}
