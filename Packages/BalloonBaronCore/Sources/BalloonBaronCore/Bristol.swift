import Foundation

// v124: Bristol (prototype `briWorld`, `bridgeH`, `briHit`, `briAirTick`, `GLOW`, `EVE`). The fog and the airport's
// airspace come with the day's weather (`Weather.fog`, `Weather.air`); see docs/GAME_DESIGN.md "Bristol (v124)".

/// What a Bristol obstacle is. The prototype's `c.k`; the crash message names it (`flight.hit.<rawValue>`).
public enum ObstacleKind: String, Codable, Sendable {
    /// A fairy chimney, cottonwood or date palm: the region's ordinary obstacle.
    case plain
    /// Bristol: oaks and copper beeches, church spires, the tall ship's masts, dock cranes, the observatory, the bridge.
    case tree, spire, mast, crane, observatory, bridge
}

/// The animals in a fenced field. Landing among them angers the farmer.
public enum PenAnimal: String, Codable, Sendable { case sheep, cow }

/// Bristol's landmarks on today's flight line: the Avon Gorge with its suspension bridge, the harbour (water, an old
/// tall ship, two cranes, mud at its edge), fields with sheep or cows, the tidal mud of the river, gulls.
public struct BristolWorld: Equatable, Sendable {
    public struct Pen: Equatable, Sendable {
        public var x0: Double, x1: Double, animal: PenAnimal, count: Int, seed: Double
    }
    public struct Span: Equatable, Sendable {
        public var x0: Double, x1: Double
        public func contains(_ x: Double) -> Bool { x > x0 && x < x1 }
    }
    public struct Gull: Equatable, Sendable {
        public var x: Double, alt: Double, phase: Double, speed: Double
    }

    /// Centre of the gorge and its bridge.
    public var bridge: Double?
    public var pens: [Pen] = []
    public var muds: [Span] = []
    public var water: [Span] = []
    public var gulls: [Gull] = []

    // The bridge as an obstacle: cliffs (52 m) on both sides out to 195 m from its centre, the towers (108 m) between
    // 92 and 108 m, and the deck with its chains between the towers (62–108 m). Never under the deck.
    public static let halfWidth = 195.0, towerOuter = 108.0, towerInner = 92.0
    public static let cliff = 52.0, tower = 108.0, deck = 62.0

    /// `bridgeH`: the height you must clear at `dx` from the bridge's centre.
    public static func bridgeHeight(_ dx: Double) -> Double {
        let a = abs(dx)
        if a > halfWidth { return 0 }
        if a > towerOuter { return cliff * pow(1 - (a - towerOuter) / (halfWidth - towerOuter), 0.5) }
        if a > towerInner { return tower }
        return deck + (tower - deck) * pow(a / towerInner, 2)
    }

    public func bridgeHeight(at x: Double) -> Double { bridge.map { Self.bridgeHeight(x - $0) } ?? 0 }

    /// Where you came down: a field with animals (the first one under you), and whether it was the tidal mud.
    public func pen(at x: Double) -> PenAnimal? { pens.first { x > $0.x0 && x < $0.x1 }?.animal }
    public func mud(at x: Double) -> Bool { muds.contains { $0.contains(x) } }

    /// `briWorld`: builds today's Bristol, clear of the launch field, the landing field, the valley mission and the
    /// power lines, and turns the plain obstacles into Bristol's (the harbour's mast and cranes, the observatory,
    /// spires on about one in seven, the rest trees). Seeded by the weather, so the app and tests see the same.
    static func build(_ w: Weather, obstacles: inout [Obstacle], lines: [PowerLine]) -> BristolWorld {
        var r = Mulberry32(seed: UInt32(truncatingIfNeeded: w.seed &+ 31))
        let tx = w.target, lx = FlightWorld.launchX
        var B = BristolWorld()
        var taken: [(Double, Double)] = [(lx - 180, lx + 180), (tx - 190, tx + 190)]
        if w.mission == .valley { taken.append((w.valley - 120, w.valley + 120)) }
        for l in lines { taken.append((l.x0 - 30, l.x1 + 30)) }
        func free(_ a: Double, _ b: Double) -> Bool { !taken.contains { b > $0.0 && a < $0.1 } }
        func place(_ half: Double, _ lo: Double, _ hi: Double) -> Double? {
            for _ in 0..<30 {
                let x = lo + r.next() * max(1, hi - lo)
                if free(x - half, x + half) { taken.append((x - half, x + half)); return x }
            }
            return nil
        }
        func clear(_ a: Double, _ b: Double) { obstacles.removeAll { !($0.x + $0.w / 2 < a || $0.x - $0.w / 2 > b) } }
        // the gorge and its bridge, most days on the way to the field
        let bx = r.next() < 0.75 ? place(halfWidth, 560, tx - 400) : place(halfWidth, -700, -260)
        if let bx {
            B.bridge = bx
            clear(bx - halfWidth, bx + halfWidth)
        }
        // the harbour: water, the tall ship, two cranes, mud at its edge
        let hx = r.next() < 0.5 ? place(230, tx + 320, tx + 900) : place(230, -900, -280)
        if let hx {
            clear(hx - 230, hx + 230)
            B.water.append(Span(x0: hx - 200, x1: hx + 120))
            obstacles.append(Obstacle(x: hx - 70, h: 64 + r.next() * 10, w: 60, tone: r.next(), kind: .mast))
            obstacles.append(Obstacle(x: hx + 60, h: 78, w: 26, tone: r.next(), kind: .crane))
            obstacles.append(Obstacle(x: hx + 175, h: 72, w: 26, tone: r.next(), kind: .crane))
            B.muds.append(Span(x0: hx - 230, x1: hx - 199))
        }
        // the observatory on its hill, a church or two
        if let ox = place(60, -500, tx + 600) {
            clear(ox - 60, ox + 60)
            obstacles.append(Obstacle(x: ox, h: 82, w: 34, tone: r.next(), kind: .observatory))
        }
        for i in obstacles.indices where obstacles[i].kind == .plain {
            if r.next() < 0.14 {
                let o = obstacles[i]
                obstacles[i] = Obstacle(x: o.x, h: max(o.h, 60), w: min(o.w, 30), tone: o.tone, kind: .spire)
            } else {
                obstacles[i].kind = .tree
            }
        }
        obstacles.sort { $0.x < $1.x }
        // tidal mud on the way, fields with animals
        if let mx = place(90, 420, tx - 260) { B.muds.append(Span(x0: mx - 80, x1: mx + 80)) }
        for _ in 0..<3 {
            if let px = place(110, 300, tx + 700) {
                B.pens.append(Pen(x0: px - 100, x1: px + 100, animal: r.next() < 0.6 ? .sheep : .cow, count: 4 + Int(r.next() * 4), seed: r.next() * 99))
            }
        }
        // a few gulls
        B.gulls = (0..<7).map { _ in Gull(x: -200 + r.next() * 2600, alt: 90 + r.next() * 420, phase: r.next() * 6, speed: 6 + r.next() * 8) }
        return B
    }
}

// MARK: Night Glow and the evening ascent

/// v124: Bristol's Night Glow (`GLOW`). Once per festival, on one of its evenings, the balloons stand on the field and
/// fire their burners to music, then fireworks. A flat fee; popularity at once, a morning story and a postcard. It is
/// its own thing next to the Balloon Show.
public enum Glow {
    public static let cost = 2500, minBalloons = 3
    public static let rep = 0.04
    /// The night scene's length and the second the fireworks start.
    public static let duration = 15.0, fireworksAt = 9.0
}

/// v124: festival days in Bristol have an evening ascent (`EVE`): the fleet goes up a second time at dusk. It is played
/// out on the report and in the evening scene, not flown by hand: half the morning's passengers at the same price,
/// 60% of the fuel.
public enum EveningAscent {
    public static let pax = 0.5, fuel = 0.6
}

/// `glowState`.
public enum GlowState: Equatable, Sendable {
    /// Not Bristol, or no festival today.
    case noFestival
    case booked
    /// This festival's glow was held (or is booked for another night).
    case done
    /// A Balloon Show is booked tonight.
    case show
    case few, cash, ok
}

extension Game {
    /// The balloons on the field: every one that can fly tonight (the show's fleet).
    public var glowFleet: [Balloon] { showFleet }

    public var glowState: GlowState {
        let l = state.local
        guard state.region.bristol, let f = l.fiesta else { return .noFestival }
        if l.glowTonight == state.day { return .booked }
        if l.glowFest == f.start { return .done }
        if l.showTonight == state.day { return .show }
        if glowFleet.count < Glow.minBalloons { return .few }
        return state.cash < Glow.cost ? .cash : .ok
    }

    /// `bookGlow`.
    @discardableResult
    public mutating func bookGlow() -> Bool {
        guard glowState == .ok, let f = state.fiesta else { return false }
        state.cash -= Glow.cost
        state.local.glowTonight = state.day
        state.local.glowFest = f.start
        state.local.glowN = glowFleet.count
        return true
    }

    /// The evening ascent and the Night Glow at the end of a Bristol festival day. Adds the evening's tickets and fuel
    /// to the ledger; returns nothing, events go to `ev`.
    mutating func bristolEvening(flying: [Int], cancelledSelf: Bool, paxTotal: Int, red: Bool, ledger lg: inout Ledger, events ev: inout [DayEvent]) {
        guard state.region.bristol else { return }
        if state.fiesta != nil && !red && paxTotal > 0 {
            let up = flying.compactMap(state.balloon).filter { $0.damagedUntil <= state.day && !(cancelledSelf && state.isSelf($0)) }
            let seats = up.reduce(0) { $0 + state.sellSeats($1) }
            let pax = jsRound(Double(min(seats, paxTotal)) * EveningAscent.pax)
            if pax > 0 {
                let fuel = jsRound(Double(up.reduce(0) { $0 + $1.size.fuel }) * EveningAscent.fuel)
                lg.evening = pax * state.price
                lg.fuel += fuel
                state.local.eveDay = state.day
                state.local.eveN = up.count
                ev.append(.eveningAscent(balloons: up.count, pax: pax, income: pax * state.price))
            }
        }
        if state.local.glowTonight == state.day {
            let n = glowFleet.count
            rep(.glow, Glow.rep)
            state.local.glowCount = (state.local.glowCount ?? 0) + 1
            addPaper(.nightGlow(balloons: n))
            ev.append(.nightGlowTonight(balloons: n))
        }
    }

    /// Bristol's landings and the airport, for your own flight (`finishDay`).
    mutating func bristolLanding(_ f: FlightResult, weather: Weather, ledger lg: inout Ledger, events ev: inout [DayEvent]) {
        if weather.fog != nil && f.landing != .crash && f.landing != .cancel {
            let n = (state.local.fogFlown ?? 0) + 1
            state.local.fogFlown = n
            if n == 1 { ev.append(.fogFlown) }
        }
        if let a = f.farm {
            lg.fines += Bristol.farmFine
            rep(.farm, -Bristol.farmRep)
            addReview(.farm)
            ev.append(.farmLanding(a, fine: Bristol.farmFine))
        }
        if f.mud == true {
            rep(.mud, -Bristol.mudRep)
            addReview(.mud)
            ev.append(.mudLanding)
        }
        if f.airFine == true {
            lg.fines += Airspace.fine
            rep(.airspace, -Airspace.rep)
            addPaper(.airspace(fine: Airspace.fine))
            ev.append(.airspaceFine(fine: Airspace.fine))
        }
    }
}

/// v124: what Bristol's landings cost.
public enum Bristol {
    /// Landing in a field with sheep or cows: the farmer's due and popularity.
    public static let farmFine = 300, farmRep = 0.015
    /// Landing in the tidal mud.
    public static let mudRep = 0.03
}
