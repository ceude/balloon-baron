import Foundation

/// Special envelope shapes sold in the bazaar. Names: `shop.<rawValue>`.
public enum Shape: String, Codable, CaseIterable, Sendable {
    case heart, star, hezarfen
}

/// Everything the bazaar sells for real money. Names: `shop.<rawValue>`.
public enum ShopItem: String, Codable, CaseIterable, CodingKeyRepresentable, Sendable {
    case gold, tile, sky, kilim
    case heart, star, hezarfen
    case fountain, statue, lanterns, flags

    public enum Kind: Sendable { case pattern, shape, decor }

    public var kind: Kind {
        switch self {
        case .gold, .tile, .sky, .kilim: .pattern
        case .heart, .star, .hezarfen: .shape
        case .fountain, .statue, .lanterns, .flags: .decor
        }
    }

    public var pattern: Pattern? { Pattern(rawValue: rawValue) }
    public var shape: Shape? { Shape(rawValue: rawValue) }
    /// Hezarfen gives the lantern strings away when he shows you the bazaar.
    public var isGift: Bool { self == .lanterns }
    /// App Store product id. Patterns and decorations sit on the first price tier, shapes on the second.
    public var productID: String { "balloonbaron.\(rawValue)" }
    public static let decor: [ShopItem] = [.fountain, .statue, .lanterns, .flags]
}

extension Pattern {
    /// Patterns bought in the bazaar.
    public var shopItem: ShopItem? { ShopItem(rawValue: rawValue) }
    public var isPremium: Bool { shopItem != nil }
}

extension GameState {
    public func owns(_ item: ShopItem) -> Bool { purchases[item] != nil }
    public var decorCount: Int { ShopItem.decor.filter(owns).count }
    /// A design using something bought with real money: it never fades and costs nothing to put on.
    public func isPaid(_ d: Design) -> Bool { d.shape != nil || d.pattern.isPremium }
}

extension Game {
    /// Records a purchase (or the gift). Patterns and shapes arrive as a ready design in your colors, worn by the flagship.
    @discardableResult
    public mutating func receive(_ item: ShopItem, announce: Bool = true) -> Bool {
        guard !state.owns(item) else { return false }
        state.purchases[item] = state.day
        giftDesign(item, announce: announce)
        return true
    }

    mutating func giftDesign(_ item: ShopItem, announce: Bool) {
        guard item.kind != .decor, !state.designs.contains(where: { $0.item == item }) else { return }
        let colors = [state.colors[0], state.colors.count > 1 ? state.colors[1] : "#ffffff", "#ffffff"]
        let pattern = item.pattern ?? .stripes, shape = item.shape
        let d = Design(id: state.nextID, name: "", number: state.designs.count + 1, pattern: pattern, colors: colors, day: state.day,
                       score: designScore(pattern: pattern, colors: colors, shape: shape), shape: shape, item: item)
        state.nextID += 1
        state.designs.append(d)
        if announce, let i = state.balloons.firstIndex(where: { $0.id == state.flagship }) ?? state.balloons.indices.first {
            state.balloons[i].design = d.id
            state.hezQueue.insert(.designGift(item, balloon: state.balloons[i].name), at: 0)
        }
    }

    /// Restores purchases kept outside the save (a new game, another device), each with its ready design.
    public mutating func restorePurchases(_ items: Set<ShopItem>) {
        for i in ShopItem.allCases where items.contains(i) && !state.owns(i) {
            state.purchases[i] = state.day
            giftDesign(i, announce: false)
        }
    }

    /// An ad watched on the chapter card pays the chapter's reward once more.
    @discardableResult
    public mutating func claimAdBonus(_ news: ChapterNews) -> Int {
        let key = "\(news.region.rawValue).\(news.index)"
        let cs = news.region.chapters
        guard !state.adClaimed.contains(key), cs.indices.contains(news.index), news.region == state.region else { return 0 }
        let r = cs[news.index].reward
        guard r > 0 else { return 0 }
        state.adClaimed.insert(key)
        state.cash += r
        return r
    }
}
