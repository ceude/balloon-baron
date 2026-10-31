import Foundation

// v125–v125.1: bringing balloons and pilots into a new region (`XFER` in the prototype). Only when you enter a new
// region: up to two balloons (16 seats, small or medium baskets) and two pilots from regions on autopilot come with you.
// Pilots arrive at once; balloons come by cargo ten days later, and the new region pays the holding back for them over
// 30 days. Balloons keep their name, design and equipment (a sponsor deal stays home); pilots keep level, experience
// and trait, their wage the same number in the new region's money (Bristol's ×1.15 on or off). The region they leave
// earns less on autopilot. What you bring doesn't count toward the new region's goals.
public enum Transfer {
    public static let maxBalloons = 2, maxPilots = 2, seats = 16
    public static let sizes: [BalloonSize] = [.S, .M]
    /// Each pilot taken cuts the home region's autopilot income by this much more.
    public static let pilotCut = 0.02
    /// Days the cargo takes, and days the new region pays back over.
    public static let shipDays = 10, debtDays = 30
    /// Brought balloons and pilots don't count toward the new region's goals (`XFER.local`).
    public static let local = true
}

/// Balloons on their way by cargo, joining the fleet on `day`.
public struct TransferShip: Codable, Equatable, Sendable {
    public var day: Int
    public var balloons: [Balloon]
}

/// What the region still pays back to the holding for the brought balloons, a little every day.
public struct TransferDebt: Codable, Equatable, Sendable {
    public var left: Int
    public var installment: Int
    public var from: RegionID
}

/// A balloon or pilot that could come along, and the region it would leave.
public struct TransferBalloon: Equatable, Sendable { public var region: RegionID; public var balloon: Balloon }
public struct TransferPilot: Equatable, Sendable { public var region: RegionID; public var pilot: Pilot }

extension Game {
    /// Balloons from regions on autopilot that can come: small and medium, not in repair, envelope above 20%;
    /// the biggest and freshest first (`xferBalloons`).
    public var transferBalloons: [TransferBalloon] {
        var out: [TransferBalloon] = []
        for r in RegionID.allCases {
            guard let p = state.parked[r] else { continue }
            for b in p.state.balloons where Transfer.sizes.contains(b.size) && b.damagedUntil <= state.day && state.condition(b) > 0.2 {
                out.append(TransferBalloon(region: r, balloon: b))
            }
        }
        return out.enumerated().sorted { a, b in
            let x = a.element.balloon, y = b.element.balloon
            if x.size.capacity != y.size.capacity { return x.size.capacity > y.size.capacity }
            if state.condition(x) != state.condition(y) { return state.condition(x) > state.condition(y) }
            return a.offset < b.offset
        }.map(\.element)
    }

    /// Pilots in regions on autopilot, the most senior first (`xferPilots`).
    public var transferPilots: [TransferPilot] {
        var out: [TransferPilot] = []
        for r in RegionID.allCases {
            guard let p = state.parked[r] else { continue }
            for pl in p.state.pilots { out.append(TransferPilot(region: r, pilot: pl)) }
        }
        return out.enumerated().sorted { a, b in
            let x = a.element.pilot, y = b.element.pilot
            if x.level != y.level { return x.level > y.level }
            if x.xp != y.xp { return x.xp > y.xp }
            return a.offset < b.offset
        }.map(\.element)
    }

    /// The card's first choice: the two best pilots and the best balloons that fit the cargo.
    public var transferDefaults: (balloons: [Int], pilots: [Int]) {
        var bs: [Int] = [], seats = 0
        for x in transferBalloons where bs.count < Transfer.maxBalloons && seats + x.balloon.size.capacity <= Transfer.seats {
            bs.append(x.balloon.id)
            seats += x.balloon.size.capacity
        }
        return (bs, transferPilots.prefix(Transfer.maxPilots).map(\.pilot.id))
    }

    /// Daily autopilot income of a home region now, and after the chosen balloons and pilots leave (euros).
    public func transferIncome(_ r: RegionID, balloons: [Int], pilots: [Int]) -> (now: Int, after: Int) {
        guard let p = state.parked[r] else { return (0, 0) }
        let s0 = p.state.balloons.reduce(0) { $0 + $1.size.capacity }
        let seats = p.state.balloons.filter { balloons.contains($0.id) }.reduce(0) { $0 + $1.size.capacity }
        let np = p.state.pilots.filter { pilots.contains($0.id) }.count
        let k = max(0, 1 - (s0 > 0 ? Double(seats) / Double(s0) : 0) - Transfer.pilotCut * Double(np))
        return (jsRound(p.auto.base), jsRound(p.auto.base * k))
    }

    /// What the chosen balloons cost the new region, paid back over `Transfer.debtDays` (local money).
    public func transferCost(balloons: [Int]) -> Int {
        let bs = transferBalloons.filter { balloons.contains($0.balloon.id) }.map(\.balloon)
        return jsRound(Double(bs.reduce(0) { $0 + $1.size.cost }) * state.region.fx)
    }

    /// Brings the chosen balloons and pilots (`xferApply`). Pilots join at once, balloons go on the cargo.
    /// Returns the names of the pilots and balloons that came.
    @discardableResult
    public mutating func applyTransfer(balloons ids: [Int], pilots pids: [Int]) -> (pilots: [String], balloons: [String]) {
        state.transferAsk = nil
        let to = state.region
        var movedB: [Balloon] = [], movedP: [Pilot] = []
        for r in RegionID.allCases {
            guard var p = state.parked[r] else { continue }
            var rs = p.state
            let seats0 = rs.balloons.reduce(0) { $0 + $1.size.capacity }
            var bs: [Balloon] = []
            for b in rs.balloons where ids.contains(b.id) && Transfer.sizes.contains(b.size)
                && movedB.count + bs.count < Transfer.maxBalloons
                && (movedB + bs).reduce(0, { $0 + $1.size.capacity }) + b.size.capacity <= Transfer.seats {
                bs.append(b)
            }
            let ps = Array(rs.pilots.filter { pids.contains($0.id) }.prefix(max(0, Transfer.maxPilots - movedP.count)))
            if bs.isEmpty && ps.isEmpty { continue }
            for var b in bs {
                rs.balloons.removeAll { $0.id == b.id }
                b.pilot = nil
                b.pinnedPilot = nil
                b.ad = nil
                b.damagedUntil = 0
                b.imported = r
                movedB.append(b)
            }
            for var pl in ps {
                rs.pilots.removeAll { $0.id == pl.id }
                for i in rs.balloons.indices {
                    if rs.balloons[i].pinnedPilot == pl.id { rs.balloons[i].pinnedPilot = nil }
                    if rs.balloons[i].pilot == pl.id { rs.balloons[i].pilot = nil }
                }
                if pl.customWage != nil || r.wageFactor != to.wageFactor {
                    pl.customWage = jsRound(Double(pl.wage) / r.wageFactor * to.wageFactor / 5) * 5
                }
                pl.imported = r
                movedP.append(pl)
            }
            if bs.contains(where: { $0.id == rs.flagship }) || !rs.balloons.contains(where: { $0.id == rs.flagship }) {
                rs.flagship = rs.balloons.first?.id ?? 0
            }
            // the region left behind earns less, in proportion
            let lost = seats0 > 0 ? Double(bs.reduce(0) { $0 + $1.size.capacity }) / Double(seats0) : 0
            let k = max(0, 1 - lost - Transfer.pilotCut * Double(ps.count))
            p.auto.base = Double(jsRound(p.auto.base * k))
            rs.netHistory = rs.netHistory.map { jsRound(Double($0) * k) }
            p.state = rs
            state.parked[r] = p
        }
        state.local.pilots += movedP
        if !movedB.isEmpty { state.local.transferShip = TransferShip(day: state.day + Transfer.shipDays, balloons: movedB) }
        assignPilots()
        if !movedP.isEmpty || !movedB.isEmpty {
            state.hezQueue.insert(.transferBrought(pilots: movedP.map(\.name), balloons: movedB.map(\.name), day: state.day + Transfer.shipDays), at: 0)
        }
        return (movedP.map(\.name), movedB.map(\.name))
    }

    /// Skips the card: start from scratch.
    public mutating func skipTransfer() { state.transferAsk = nil }

    /// The cargo arrives in the morning (`xferArrive`): the balloons join the fleet and the payments start.
    mutating func transferArrive() {
        guard let x = state.local.transferShip, state.day >= x.day else { return }
        state.local.transferShip = nil
        let n0 = state.outsideCount
        state.local.balloons += x.balloons
        assignPilots()
        defer { hangarWarn(outsideBefore: n0, queue: true) } // v127: after the cargo's own card
        let due = jsRound(Double(x.balloons.reduce(0) { $0 + $1.size.cost }) * state.region.fx)
        if due > 0, let from = x.balloons.first?.imported {
            state.local.transferDebt = TransferDebt(left: Transfer.debtDays, installment: jsRound(Double(due) / Double(Transfer.debtDays)), from: from)
        }
        state.hezQueue.append(.cargoArrived(x.balloons.map(\.name)))
    }

    /// One day's payment to the holding for the brought balloons (local money; the holding gets euros).
    mutating func transferPay(_ lg: inout Ledger) {
        guard var d = state.local.transferDebt else { return }
        lg.transfer = d.installment
        state.holding.cash += jsRound(Double(d.installment) / state.region.fx)
        d.left -= 1
        state.local.transferDebt = d.left > 0 ? d : nil
    }
}
