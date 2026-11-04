import Foundation

// v141: the Maasai Mara, the fifth and hardest region (prototype `MARA_FX`, `maraWorld`, `maraHerdAt`, `maraRiverAt`,
// `maraHit`, the rains in `finishDay`). See docs/GAME_DESIGN.md "Maasai Mara (v141)".

/// The Mara's numbers in one place (the prototype's `MARA_FX`), tuned with tools/sim-campaign.js.
public enum Mara {
    /// Euros the holding pays to enter ($330,000).
    public static let entryFee = 300_000
    public static let startCash = 6000, startPrice = 210, startDemand = 125
    /// The reserve's fee for every passenger flown, in dollars (a line on the report). v141.1 (developer): $12 → $10.
    public static let parkFee = 10
    /// Fuel trucked in from Nairobi, bush pilots' wages.
    public static let fuel = 1.3, wage = 1.1
    /// The weather outside the rains, and in them: green below the first, yellow below the second, red above.
    /// v141.1 (developer: milder rains, tuned with tools/sim-bankrupt.js): in the rains 28% green, 34% yellow, 38% red
    /// (was 25/33/42).
    public static let green = 0.45, yellow = 0.82, rainsGreen = 0.28, rainsYellow = 0.62
    /// The rains: tourists ×0.55 (was ×0.5); the long rains (10 days, was 12) and the short rains (5, was 6) take turns, the
    /// next 45 days (was 40) after the last ends, and they don't come to a newcomer with less than $20,000 in the box.
    public static let rainsDemand = 0.55, longRains = 10, shortRains = 5, rainsEvery = 45, rainsCash = 20000
    /// v141.1: what a transfer to the holding leaves in the Mara's cash box (10,000 elsewhere): its bush days cost more to
    /// run, and a careful player who sent everything away lost balloons to the bank after red days and antitrust fines.
    public static let withdrawKeep = 50000
    /// The first rains a month in, the first migration after 16 days.
    public static let firstRains = 30, firstMigration = 16
    /// The Great Migration: six days about every six weeks (36 days after the last ends), demand ×1.8.
    public static let migration = 1.8, migrationDays = 6, migrationEvery = 36
    /// Coming down among a herd: the rangers' fine and popularity.
    public static let herdFine = 1200, herdRep = 0.03
}

/// v141: the animals of a herd on the plain (`flight.herd.<rawValue>`).
public enum HerdKind: String, Codable, CaseIterable, Sendable { case gnu, zebra, elephant, giraffe }

/// v141: the Mara on today's flight line: the Mara River (coming down in it or on its steep banks is a crash), herds
/// grazing slowly across the plain (coming down among them is the rangers' fine), granite kopjes and flat-topped
/// acacias to fly over, vultures circling. No power lines on the savanna. In the Great Migration there are more herds.
public struct MaraWorld: Equatable, Sendable {
    public struct River: Equatable, Sendable {
        public var x0: Double, x1: Double
        /// The water and its banks.
        public func contains(_ x: Double) -> Bool { x > x0 - MaraWorld.bank && x < x1 + MaraWorld.bank }
    }
    public struct Herd: Equatable, Sendable {
        /// The middle of its patch, half its width, what it is, how many, its phase and drawing seed.
        public var x: Double, half: Double, kind: HerdKind, count: Int, phase: Double, seed: Double
        /// `herdX`: it sways within its own patch, `sway` metres either way over about two minutes of flight.
        public func center(at t: Double) -> Double { x + sin(t / 20 + phase) * MaraWorld.sway }
        public func contains(_ x: Double, at t: Double) -> Bool { abs(x - center(at: t)) < half }
    }
    public struct Bird: Equatable, Sendable { public var x: Double, alt: Double, phase: Double, radius: Double }

    /// Metres of steep, muddy bank on each side of the water that count as the river.
    public static let bank = 40.0
    /// Metres a herd wanders either way of its patch.
    public static let sway = 45.0
    public var river: River?
    public var herds: [Herd] = []
    public var birds: [Bird] = []

    public func herd(at x: Double, time t: Double) -> HerdKind? { herds.first { $0.contains(x, at: t) }?.kind }
    public func inRiver(_ x: Double) -> Bool { river?.contains(x) ?? false }

    /// `maraWorld`: today's Mara, clear of the launch field and the landing field. On a valley mission the river is the
    /// valley (fly low over it, never land). Seeded by the weather, so the app and tests see the same.
    static func build(_ w: Weather, obstacles: inout [Obstacle], migration: Bool) -> MaraWorld {
        var r = Mulberry32(seed: UInt32(truncatingIfNeeded: w.seed &+ 41))
        let tx = w.target, lx = FlightWorld.launchX
        var M = MaraWorld()
        var taken: [(Double, Double)] = [(lx - 180, lx + 180), (tx - 190, tx + 190)]
        func free(_ a: Double, _ b: Double) -> Bool { !taken.contains { b > $0.0 && a < $0.1 } }
        func place(_ half: Double, _ lo: Double, _ hi: Double) -> Double? {
            for _ in 0..<30 {
                let x = lo + r.next() * max(1, hi - lo)
                if free(x - half, x + half) { taken.append((x - half, x + half)); return x }
            }
            return nil
        }
        func clear(_ a: Double, _ b: Double) { obstacles.removeAll { !($0.x + $0.w / 2 < a || $0.x - $0.w / 2 > b) } }
        // the river, most days between you and the field
        let rx: Double?
        if w.mission == .valley { rx = w.valley; taken.append((w.valley - 150, w.valley + 150)) }
        else { rx = r.next() < 0.8 ? place(150, 560, tx - 380) : place(150, -700, -280) }
        if let rx { M.river = River(x0: rx - 60, x1: rx + 60); clear(rx - 150, rx + 150) }
        // granite kopjes
        for _ in 0..<2 {
            if let kx = place(55, -500, tx + 600) {
                clear(kx - 55, kx + 55)
                obstacles.append(Obstacle(x: kx, h: 66 + r.next() * 16, w: 74, tone: r.next(), kind: .kopje))
            }
        }
        // acacias: wide, flat crowns, a little lower than the chimneys
        for i in obstacles.indices where obstacles[i].kind == .plain {
            let o = obstacles[i]
            obstacles[i] = Obstacle(x: o.x, h: 38 + (o.h - 30) * 0.6, w: o.w * 1.25, tone: o.tone, kind: .acacia)
        }
        obstacles.sort { $0.x < $1.x }
        // herds on the plain
        let kinds: [HerdKind] = migration ? [.gnu, .zebra, .gnu, .gnu, .zebra] : [.gnu, .zebra, r.next() < 0.5 ? .elephant : .giraffe]
        for i in 0..<(migration ? 5 : 3) {
            let half = (migration ? 80 : 55) + r.next() * 40
            guard let hx = place(half + sway + 20, 300, tx + 900) else { continue }
            let k = kinds[i % kinds.count]
            let n = k == .elephant ? 4 + Int(r.next() * 3) : k == .giraffe ? 3 + Int(r.next() * 3) : jsRound(half / 9 + r.next() * 6)
            M.herds.append(Herd(x: hx, half: half, kind: k, count: n, phase: r.next() * 6.3, seed: r.next() * 99))
        }
        M.birds = (0..<5).map { _ in Bird(x: -200 + r.next() * 2600, alt: 160 + r.next() * 320, phase: r.next() * 6, radius: 30 + r.next() * 40) }
        return M
    }
}

extension Game {
    /// v141: the Mara's rains in place of winter: they begin and end at the close of a day played there.
    mutating func maraRains() {
        if let w = state.winter, state.day > w.end {
            state.winter = nil
            state.nextWinter = state.day + Mara.rainsEvery
            state.local.rainsDone = (state.local.rainsDone ?? 0) + 1
            state.hezQueue.append(.rainsOver)
        } else if state.winter == nil && state.day >= (state.nextWinter ?? Mara.firstRains) && state.cash >= Mara.rainsCash {
            let n = state.local.rainsCount ?? 0, long = n % 2 == 0, days = long ? Mara.longRains : Mara.shortRains
            state.local.rainsCount = n + 1
            state.winter = Winter(start: state.day, end: state.day + days - 1, long: long)
            state.hezQueue.append(.rainsComing(long: long, days: days))
        }
    }

    /// v141: the Mara's landings, for your own flight (`finishDay`): among a herd (the rangers' fine), in the river.
    mutating func maraLanding(_ f: FlightResult, ledger lg: inout Ledger, events ev: inout [DayEvent]) {
        if let k = f.herd {
            lg.fines += Mara.herdFine
            rep(.herd, -Mara.herdRep)
            addReview(.herd)
            addPaper(.herdLanding(fine: Mara.herdFine))
            ev.append(.herdLanding(k, fine: Mara.herdFine))
        }
        if f.river == true {
            addReview(.river)
            addPaper(.riverLanding)
            ev.append(.riverLanding)
        }
    }
}
