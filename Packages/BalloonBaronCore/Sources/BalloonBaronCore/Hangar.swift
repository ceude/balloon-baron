import Foundation

/// v127: the hangar has room for `Hangar.capacity[level]` balloons (level 1 to 8). The rest stand outside: they can't be
/// maintained there, so they don't fly, get no pilot, cost no upkeep and don't count as flying or market capacity
/// (the Balloon Show, contracts, the autopilot). Owned-seat goals and achievements still count them. The flagship is
/// always inside; of the others, the ones bought first are inside and the newest stand outside, moving in by themselves
/// when the hangar grows. Buying, take-overs, the factory and the cargo are never blocked.
public enum Hangar {
    /// Balloons the hangar holds, by level (index 0 unused).
    public static let capacity = [0, 6, 12, 24, 48, 96, 192, 384, 768]
    public static let maxLevel = 8
    /// Hezarfen's reminder about balloons outside comes at most once in this many days.
    public static let reminderDays = 5
}

extension RegionState {
    public var hangarCapacity: Int { Hangar.capacity[clamp(level(.hangar), 1, Hangar.maxLevel)] }

    /// Ids of the balloons outside the hangar, newest first to go out; empty while everything fits.
    public var outsideIDs: Set<Int> {
        let cap = hangarCapacity
        guard balloons.count > cap else { return [] }
        var room = cap - (balloons.contains { $0.id == flagship } ? 1 : 0)
        var out = Set<Int>()
        for b in balloons where b.id != flagship {
            if room > 0 { room -= 1 } else { out.insert(b.id) }
        }
        return out
    }

    public func isOutside(_ b: Balloon) -> Bool {
        let cap = hangarCapacity
        guard balloons.count > cap, b.id != flagship, let i = balloons.firstIndex(where: { $0.id == b.id }) else { return false }
        // Balloons before this one that take room (the flagship is counted apart: it always has its place).
        let before = balloons[..<i].reduce(0) { $0 + ($1.id == flagship ? 0 : 1) }
        let room = cap - (balloons.contains { $0.id == flagship } ? 1 : 0)
        return before >= room
    }

    /// The balloons inside the hangar, in fleet order.
    public var insideBalloons: [Balloon] {
        let out = outsideIDs
        return out.isEmpty ? balloons : balloons.filter { !out.contains($0.id) }
    }
}

extension GameState {
    public var hangarCapacity: Int { local.hangarCapacity }
    public var outsideIDs: Set<Int> { local.outsideIDs }
    public var outsideCount: Int { max(0, local.balloons.count - local.hangarCapacity) }
    public func isOutside(_ b: Balloon) -> Bool { local.isOutside(b) }
    public var insideBalloons: [Balloon] { local.insideBalloons }
}

extension Game {
    /// After a purchase, a take-over, the factory or the cargo: when more balloons stand outside than `before`, the
    /// morning reminder waits `Hangar.reminderDays`. With `queue` (things that happen during the day) Hezarfen says so
    /// (`HezMessage.hangarFull`); the app shows its own card after the player's own purchases. Returns how many are
    /// outside now when that grew, else nil.
    @discardableResult
    public mutating func hangarWarn(outsideBefore before: Int, queue: Bool = false) -> Int? {
        let n = state.outsideCount
        guard n > before else { return nil }
        state.local.hangarReminder = state.day + Hangar.reminderDays
        if queue { state.hezQueue.append(.hangarFull(n)) }
        return n
    }

    /// The morning reminder about balloons outside, at most once every `Hangar.reminderDays` days.
    mutating func hangarReminder() {
        let n = state.outsideCount
        guard n > 0, state.day >= (state.local.hangarReminder ?? 0) else { return }
        state.local.hangarReminder = state.day + Hangar.reminderDays
        state.hezQueue.append(.hangarOutside(n))
    }
}
