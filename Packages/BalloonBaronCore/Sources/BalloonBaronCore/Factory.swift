import Foundation

/// v114: the balloon workshop grows into a factory (prototype `FAB`). Level 1 designs; level 2 builds small balloons,
/// 3 medium, 4 large, at half price, one at a time. Now and then, while the line is free, a rival asks you for a balloon
/// it wouldn't buy otherwise: the money is yours, the rival grows by a balloon.
public struct Factory: Codable, Equatable, Sendable {
    public var level = 1
    public var job: FactoryJob?
    public var order: FactoryOrder?
    /// Your own balloons started and delivered, rival orders taken, and what it all brought.
    public var built = 0
    public var made = 0
    public var orders = 0
    public var saved = 0
    public var earned = 0

    public init() {}
}

/// The balloon on the line; for a rival it carries the rival's name and the price paid on delivery.
public struct FactoryJob: Codable, Equatable, Sendable {
    public var size: BalloonSize
    public var done: Int
    public var region: RegionID
    public var rival: String?
    public var price: Int

    public init(size: BalloonSize, done: Int, region: RegionID, rival: String?, price: Int) {
        self.size = size
        self.done = done
        self.region = region
        self.rival = rival
        self.price = price
    }
}

/// A rival's request, good for the day it arrives.
public struct FactoryOrder: Codable, Equatable, Sendable {
    public var rival: String
    public var size: BalloonSize
    public var price: Int
    public var until: Int
    public var seen: Int?

    public init(rival: String, size: BalloonSize, price: Int, until: Int) {
        self.rival = rival
        self.size = size
        self.price = price
        self.until = until
    }
}

extension GameState {
    /// 0 without a workshop, else 1–4.
    public var factoryLevel: Int { workshopDay == nil ? 0 : (factory?.level ?? 1) }
    public var factorySizes: [BalloonSize] { Array(BalloonSize.shop.prefix(max(0, factoryLevel - 1))) }
    public func factoryCan(_ z: BalloonSize) -> Bool { factorySizes.contains(z) }
    public var factoryBusy: Bool { factory?.job != nil }
    /// What the next level costs, nil at the top (or without a workshop).
    public var factoryNextCost: Int? {
        let l = factoryLevel
        return l >= 1 && l <= Rules.factoryLevelCost.count ? Rules.factoryLevelCost[l - 1] : nil
    }
    public func factoryCost(_ z: BalloonSize) -> Int { Int((Double(z.cost) * (1 - Rules.factoryDiscount) / 100).rounded()) * 100 }
    public func factoryPrice(_ z: BalloonSize) -> Int { Int((Double(z.cost) * Rules.factoryOrderShare / 100).rounded()) * 100 }
    /// The order card is due this morning: unseen, and the line is free to take it.
    public var factoryOrderDue: Bool { factory?.order.map { $0.seen != day && $0.until >= day } == true && !factoryBusy }
}

extension Game {
    @discardableResult
    public mutating func upgradeFactory() -> Bool {
        guard let c = state.factoryNextCost, state.cash >= c else { return false }
        state.cash -= c
        var f = state.factory ?? Factory()
        f.level = state.factoryLevel + 1
        state.factory = f
        addPaper(.factoryGrew(company: state.company, level: f.level))
        return true
    }

    /// Your own balloon: paid now, ready in a few days.
    @discardableResult
    public mutating func buildBalloon(_ z: BalloonSize) -> Bool {
        let cost = state.factoryCost(z)
        guard state.factoryCan(z), !state.factoryBusy, state.cash >= cost, var f = state.factory else { return false }
        state.cash -= cost
        f.job = FactoryJob(size: z, done: state.day + Rules.factoryDays(z), region: state.region, rival: nil, price: 0)
        f.built += 1
        state.factory = f
        return true
    }

    public mutating func markFactoryOrderSeen() { state.factory?.order?.seen = state.day }

    /// A rival's order: they pay on delivery; until then the line is theirs.
    @discardableResult
    public mutating func acceptFactoryOrder() -> Bool {
        guard var f = state.factory, let o = f.order, f.job == nil else { return false }
        if let i = state.local.rivals.firstIndex(where: { $0.name == o.rival }) { state.local.rivals[i].cash -= Double(o.size.cost) * 0.5 }
        f.job = FactoryJob(size: o.size, done: state.day + Rules.factoryDays(o.size), region: state.region, rival: o.rival, price: o.price)
        f.order = nil
        f.orders += 1
        state.factory = f
        return true
    }

    /// Turned down: no deal, the rival stays as it is.
    public mutating func declineFactoryOrder() { state.factory?.order = nil }

    /// After the rivals' day: with the line free, sometimes one of them asks for a balloon (`fabOrderRoll`). The size
    /// is what it flies (large for the safe ones, else medium), or the biggest you can make.
    mutating func factoryOrderRoll(_ rev: inout [DayEvent]) {
        guard state.factoryLevel >= 2, !state.factoryBusy, state.factory?.order == nil, rng.chance(Rules.factoryOrderChance) else { return }
        let rs = state.local.rivals.filter { $0.alive && $0.balloons.count < 30 && $0.cash > 5000 }
        guard !rs.isEmpty else { return }
        let r = rng.pick(rs), pref: BalloonSize = r.style == .safe ? .L : .M
        let z: BalloonSize = state.factoryCan(pref) ? pref : state.factoryCan(.M) ? .M : .S
        let o = FactoryOrder(rival: r.name, size: z, price: state.factoryPrice(z), until: state.day + 1)
        state.factory?.order = o
        rev.append(.factoryOrderAsk(rival: r.name, size: z))
    }

    /// After the day: a finished balloon goes to its owner; an unanswered order lapses.
    mutating func factoryDay(_ ev: inout [DayEvent], tomorrow: Int) {
        guard var f = state.factory else { return }
        if let o = f.order, o.until < tomorrow { f.order = nil }
        guard let j = f.job, tomorrow >= j.done else { state.factory = f; return }
        f.job = nil
        if let name = j.rival {
            state.cash += j.price
            f.earned += j.price - state.factoryCost(j.size)
            if let i = state.local.rivals.firstIndex(where: { $0.name == name && $0.alive }) {
                state.local.rivals[i].balloons.append(j.size)
                state.local.rivals[i].damagedUntil.append(0)
                ev.append(.factoryDelivered(rival: name, size: j.size, price: j.price))
            } else {
                ev.append(.factoryKept(rival: name, price: j.price))
                state.factory = f
                let n0 = state.outsideCount
                addBalloon(j.size)
                assignPilots()
                hangarWarn(outsideBefore: n0, queue: true)
                return
            }
        } else {
            f.saved += j.size.cost - state.factoryCost(j.size)
            f.made += 1
            if j.region == state.region {
                state.factory = f
                let n0 = state.outsideCount
                addBalloon(j.size)
                assignPilots()
                hangarWarn(outsideBefore: n0, queue: true)
                ev.append(.factoryReady(balloon: state.balloons.last?.name ?? "", size: j.size))
                return
            } else if var p = state.parked[j.region] {
                let used = Set(p.state.balloons.map(\.name))
                p.state.balloons.append(Balloon(id: state.nextID, size: j.size, name: j.region.balloonNames.first { !used.contains($0) } ?? Rules.defaultBalloonName(state.nextID)))
                state.nextID += 1
                state.parked[j.region] = p
            }
        }
        state.factory = f
    }
}
