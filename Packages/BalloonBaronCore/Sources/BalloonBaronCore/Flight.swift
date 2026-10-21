import Foundation

/// The prototype's seedable generator (mulberry32), so terrain and scenery look the same everywhere.
public struct Mulberry32: Sendable {
    private var a: UInt32
    public init(seed: UInt32) { a = seed }
    public mutating func next() -> Double {
        a = a &+ 0x6D2B_79F5
        var q = (a ^ (a >> 15)) &* (1 | a)
        q = (q &+ ((q ^ (q >> 7)) &* (61 | q))) ^ q
        return Double(q ^ (q >> 14)) / 4_294_967_296
    }
}

/// A fairy chimney (or a cottonwood tree in Albuquerque) you can crash into. x in meters, h in meters.
public struct Obstacle: Equatable, Sendable {
    public let x: Double, h: Double, w: Double, tone: Double
}

public enum FlightWorld {
    /// Wind band edges and centers in meters.
    public static let bands: [ClosedRange<Double>] = [0...60, 60...180, 180...350, 350...650]
    public static let launchX = 220.0
    /// Simulation speed: one real second is this many flight seconds.
    public static let timeScale = 6.0
    public static let landingZone = 70.0

    /// Obstacles along the course, kept clear of the launch field, landing zone and valley.
    public static func obstacles(for w: Weather) -> [Obstacle] {
        var r = Mulberry32(seed: UInt32(truncatingIfNeeded: w.seed))
        var out: [Obstacle] = []
        var x = -600.0
        // The prototype steps with Math.random; a second seeded sequence keeps it deterministic.
        var step = Mulberry32(seed: UInt32(truncatingIfNeeded: w.seed &+ 7))
        while x < 4200 {
            let skip = abs(x - launchX) < 160 || abs(x - w.target) < 140 || (w.mission == .valley && abs(x - w.valley) < 110)
            if !skip { out.append(Obstacle(x: x, h: 30 + r.next() * 65, w: 26 + r.next() * 22, tone: r.next())) }
            x += 90 + step.next() * 100
        }
        return out
    }

    public static func terrainHeight(at x: Double, _ obs: [Obstacle]) -> Double {
        var h = 0.0
        for c in obs {
            let d = abs(x - c.x)
            if d < c.w / 2 { h = max(h, c.h * pow(1 - d / (c.w / 2), 0.6)) }
        }
        return h
    }

    /// Wind speed (m/s, + is east) at an altitude, blended smoothly between band centers, with gusts.
    public static func wind(at alt: Double, time t: Double, _ w: Weather) -> Double {
        let ls = w.layers, c = Rules.windCenters
        var v: Double
        if alt <= c[0] {
            v = ls[0]
        } else if alt >= c[3] {
            v = ls[3]
        } else {
            var i = 0
            while alt > c[i + 1] { i += 1 }
            let k = (alt - c[i]) / (c[i + 1] - c[i])
            let s = clamp((k - 0.5) / 0.35 + 0.5, 0, 1), sm = s * s * (3 - 2 * s)
            v = lerp(ls[i], ls[i + 1], sm)
        }
        return v + w.flag.gust * 0.6 * (sin(t * 0.11 + alt * 0.013) + 0.6 * sin(t * 0.37 + alt * 0.031))
    }
}

/// A small moment most flights bring: a thermal to ride, another balloon to greet, a sunrise photo spot.
/// Text: `moment.<rawValue>.*`.
public enum Moment: String, Codable, CaseIterable, Sendable {
    case thermal, greet, photo
}

/// Where today's moment is and how long you've held it.
public struct MomentState: Equatable, Sendable {
    public let kind: Moment
    /// Thermal column, greeting balloon or photo spot, in meters; the other balloon drifts with the wind.
    public var x: Double
    /// The other balloon's altitude (greet).
    public var alt: Double
    /// Photo band.
    public static let photoBand: ClosedRange<Double> = 150...280
    /// The other balloon's colors (greet), from `MomentState.colors`.
    public let colorIndex: Int
    public var held = 0.0
    public var done = false
    public static let colors = [["#14a39a", "#e8fff9"], ["#9b7be0", "#f2ebff"], ["#5aa9e6", "#eaf4fc"], ["#e0408a", "#ffd0e0"]]
    public static let thermalHalfWidth = 65.0, thermalTop = 520.0
}

/// The player's own flight: hold the burner to heat and climb, let go to cool and sink.
public struct FlightSim: Sendable {
    public enum Event: Equatable, Sendable { case airborne, missionDone, fuelOut, landed, momentDone(Moment) }

    public let weather: Weather
    public let obstacles: [Obstacle]
    public let pax: Int
    public var x = FlightWorld.launchX, alt = 0.0, vx = 0.0, vy = 0.0
    public var heat = 0.42, fuel = 100.0
    /// Flight time in simulated seconds.
    public var t = 0.0
    public var airborne = false, done = false, burning = false, fuelWarned = false
    public var mission: Mission? { weather.mission }
    /// Seconds held inside the proposal band.
    public var missionProgress = 0.0
    public var missionDone = false
    public var result: FlightResult?
    /// Seven flights in ten bring a moment.
    public var moment: MomentState?

    public init(weather: Weather, pax: Int) {
        self.weather = weather
        self.pax = pax
        obstacles = FlightWorld.obstacles(for: weather)
        var r = Mulberry32(seed: UInt32(truncatingIfNeeded: weather.seed &+ 31))
        let dir: Double = weather.target >= FlightWorld.launchX ? 1 : -1
        if r.next() < 0.7 {
            let kind = Moment.allCases[min(2, Int(r.next() * 3))]
            let lx = FlightWorld.launchX
            switch kind {
            case .thermal:
                moment = MomentState(kind: kind, x: lx + dir * (350 + r.next() * 450), alt: 0, colorIndex: 0)
            case .greet:
                let x = lx + dir * (500 + r.next() * 400), a = 160 + r.next() * 160
                moment = MomentState(kind: kind, x: x, alt: a, colorIndex: min(3, Int(r.next() * 4)))
            case .photo:
                moment = MomentState(kind: kind, x: lx + dir * (450 + r.next() * 550), alt: 0, colorIndex: 0)
            }
        }
    }

    public var distanceToTarget: Double { abs(x - weather.target) }

    /// Advances by `dt` real seconds and returns what happened.
    public mutating func step(_ dt: Double) -> [Event] {
        guard !done else { return [] }
        var ev: [Event] = []
        let s = dt * FlightWorld.timeScale
        if burning && fuel > 0 {
            heat += 0.05 * s
            fuel = max(0, fuel - 2 * dt)
        }
        heat = clamp(heat - 0.012 * s, 0, 1)
        let acc = (heat - 0.5) * 4 - 0.4 * vy
        vy = clamp(vy + acc * s, -6, 6)
        alt += vy * s
        if !airborne && alt <= 0 { alt = 0; vy = max(0, vy) }
        let w = FlightWorld.wind(at: alt, time: t, weather)
        if alt > 1 {
            vx += (w - vx) * (1 - exp(-s / 6))
            x += vx * s
        }
        t += s
        if alt > 15 && !airborne { airborne = true; ev.append(.airborne) }
        if airborne {
            let th = FlightWorld.terrainHeight(at: x, obstacles)
            if th > 4 && alt < th { land(.crash); return ev + [.landed] }
            if alt <= 0 {
                alt = 0
                let before = missionDone
                land(-vy > 2.6 ? .hard : nil)
                if missionDone && !before { ev.append(.missionDone) }
                return ev + [.landed]
            }
        }
        if let m = mission, !missionDone && airborne {
            switch m {
            case .proposal:
                if alt >= 250 && alt <= 350 {
                    missionProgress += dt
                    if missionProgress >= 8 { missionDone = true; ev.append(.missionDone) }
                } else {
                    missionProgress = 0
                }
            case .valley:
                if abs(x - weather.valley) < 60 && alt < 150 { missionDone = true; ev.append(.missionDone) }
            case .panorama:
                if alt >= 550 { missionDone = true; ev.append(.missionDone) }
            case .precision:
                break
            }
        }
        if var m = moment {
            if m.kind == .greet { m.x += FlightWorld.wind(at: m.alt, time: t, weather) * s * 0.9 }
            if !m.done && airborne {
                switch m.kind {
                case .thermal:
                    if abs(x - m.x) < MomentState.thermalHalfWidth && alt < MomentState.thermalTop {
                        vy += 0.5 * s
                        m.held += dt
                        if m.held > 2 { m.done = true; fuel = min(100, fuel + 15) }
                    }
                case .greet:
                    if abs(x - m.x) < 95 && abs(alt - m.alt) < 50 {
                        m.held += dt
                        if m.held > 2 { m.done = true }
                    } else {
                        m.held = 0
                    }
                case .photo:
                    if abs(x - m.x) < 70 && MomentState.photoBand.contains(alt) {
                        m.held += dt
                        if m.held > 1.5 { m.done = true }
                    }
                }
                if m.done { ev.append(.momentDone(m.kind)) }
            }
            moment = m
        }
        if airborne && alt > 0 && fuel <= 0 && !fuelWarned { fuelWarned = true; ev.append(.fuelOut) }
        return ev
    }

    mutating func land(_ q: FlightResult.Landing?) {
        done = true
        burning = false
        let dist = distanceToTarget
        let landing = q ?? (dist < FlightWorld.landingZone ? .perfect : dist < 260 ? .good : .far)
        if mission == .precision && dist < 40 && landing != .hard && landing != .crash { missionDone = true }
        result = FlightResult(landing: landing, distance: dist, mission: mission, missionDone: mission != nil && missionDone,
                              moment: moment?.done == true ? moment?.kind : nil)
    }

    /// Cancel before take-off: passengers get refunds and compensation.
    public mutating func cancel() {
        guard !airborne, !done else { return }
        done = true
        burning = false
        result = FlightResult(landing: .cancel, mission: mission)
    }
}
