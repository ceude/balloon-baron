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
    /// v124: what it is in Bristol (a tree, a spire, the tall ship…); `.plain` elsewhere.
    public var kind: ObstacleKind = .plain
}

/// Power lines across the fields: two poles and the wire between, sagging 12 m in the middle. Never fly low under one.
public struct PowerLine: Equatable, Sendable {
    public let x0: Double, x1: Double, h: Double
    public static let sag = 12.0
    /// Height of the wire at x, nil outside the span.
    public func wire(at x: Double) -> Double? {
        guard x > x0 && x < x1 else { return nil }
        let k = (x - x0) / (x1 - x0)
        return h - Self.sag * 4 * k * (1 - k)
    }
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

    /// Up to three power lines, clear of the launch field, the landing zone, the valley and each other.
    public static func powerLines(for w: Weather) -> [PowerLine] {
        var r = Mulberry32(seed: UInt32(truncatingIfNeeded: w.seed &+ 21))
        var out: [PowerLine] = []
        for _ in 0..<3 {
            let x0 = -300 + r.next() * 3600, x1 = x0 + 190 + r.next() * 90, h = 42 + r.next() * 16
            if x1 > launchX - 170 && x0 < launchX + 170 { continue }
            if x1 > w.target - 180 && x0 < w.target + 180 { continue }
            if w.mission == .valley && x1 > w.valley - 120 && x0 < w.valley + 120 { continue }
            if out.contains(where: { x1 > $0.x0 - 80 && x0 < $0.x1 + 80 }) { continue }
            out.append(PowerLine(x0: x0, x1: x1, h: h))
        }
        return out
    }

    public static func terrainHeight(at x: Double, _ obs: [Obstacle], lines: [PowerLine] = [], bristol: BristolWorld? = nil) -> Double {
        var h = bristol?.bridgeHeight(at: x) ?? 0
        for c in obs {
            let d = abs(x - c.x)
            if d < c.w / 2 { h = max(h, c.h * pow(1 - d / (c.w / 2), 0.6)) }
        }
        for l in lines { if let y = l.wire(at: x) { h = max(h, y) } }
        return h
    }

    /// Wind speed (m/s, + is east) at an altitude: each band's wind, changing at the band edges, with gusts.
    public static func wind(at alt: Double, time t: Double, _ w: Weather) -> Double {
        baseWind(at: alt, w) + w.flag.gust * 0.6 * (sin(t * 0.11 + alt * 0.013) + 0.6 * sin(t * 0.37 + alt * 0.031))
    }

    /// The layer wind at a height without gusts: what the arrows on the left and the tag under the basket show.
    public static func baseWind(at alt: Double, _ w: Weather) -> Double {
        let ls = w.layers, c = Rules.windCenters
        var v: Double
        if alt <= c[0] {
            v = ls[0]
        } else if alt >= c[3] {
            v = ls[3]
        } else {
            // v111: the change happens at the dashed line between the layers (the band edge), so just over the line
            // you're already in the next layer's wind.
            var i = 0
            while alt > c[i + 1] { i += 1 }
            let b = FlightWorld.bands[i + 1].lowerBound
            let s = clamp((alt - (b - Rules.windBlend / 2)) / Rules.windBlend, 0, 1), sm = s * s * (3 - 2 * s)
            v = lerp(ls[i], ls[i + 1], sm)
        }
        return v
    }
}

/// Most flights bring a small moment: a thermal to ride, another balloon to greet, a sunrise photo spot.
public struct FlightMoment: Equatable, Sendable {
    public enum Kind: String, Codable, Sendable { case thermal, greet, photo }
    public var kind: Kind
    /// Where it is: the thermal's column, the other balloon (it drifts), the photo spot's centre.
    public var x: Double
    /// The other balloon's altitude; the photo band is 150–280 m.
    public var alt = 0.0
    public static let photoBand = 150.0...280.0
    /// Index into the greeting balloon's colors.
    public var colors = 0
    /// Seconds spent in it so far.
    public var progress = 0.0
    public var done = false

    public static let greetColors: [[String]] = [["#14a39a", "#e8fff9"], ["#9b7be0", "#f2ebff"], ["#5aa9e6", "#eaf4fc"], ["#e0408a", "#ffd0e0"]]

    /// 70% of flights get one, ahead of you in the direction of the landing field.
    static func roll(_ w: Weather) -> FlightMoment? {
        var r = Mulberry32(seed: UInt32(truncatingIfNeeded: w.seed &+ 13))
        guard r.next() < 0.7 else { return nil }
        let dir = w.target >= FlightWorld.launchX ? 1.0 : -1.0, x0 = FlightWorld.launchX
        func span(_ a: Double, _ b: Double) -> Double { x0 + dir * (a + r.next() * (b - a)) }
        switch Int(r.next() * 3) {
        case 0: return FlightMoment(kind: .thermal, x: span(350, 800))
        case 1:
            let x = span(500, 900)
            return FlightMoment(kind: .greet, x: x, alt: 160 + r.next() * 160, colors: Int(r.next() * 4))
        default: return FlightMoment(kind: .photo, x: span(450, 1000))
        }
    }
}

/// The player's own flight: hold the burner to heat and climb, let go to cool and sink.
public struct FlightSim: Sendable {
    public enum Event: Equatable, Sendable {
        case airborne, missionDone, fuelOut, landed, moment(FlightMoment.Kind)
        /// v124: flying into the airport's airspace (a warning), and staying in it three seconds (the fine is coming).
        case airspaceWarning, airspaceViolated
    }

    public let weather: Weather
    public let obstacles: [Obstacle]
    public let lines: [PowerLine]
    public let pax: Int
    /// Burner power from the flagship's burners (1, 1.3, 1.6), and its turning vent.
    public let burnerPower: Double
    public let turningVent: Bool
    /// Holding the parachute vent open: hot air leaves through the crown and you sink fast.
    public var venting = false
    /// The crash was into a power line.
    public var hitWire = false
    /// v124: Bristol's landmarks on today's flight line (nil elsewhere), and what a crash hit there.
    public let bristol: BristolWorld?
    public var hit: ObstacleKind?
    /// v124: inside the airport's airspace now, seconds in it, warned, fined.
    public var inAirspace = false
    public var airspaceTime = 0.0
    public var airspaceWarned = false, airspaceFined = false
    public var x = FlightWorld.launchX, alt = 0.0, vx = 0.0, vy = 0.0
    public var heat = 0.42, fuel = 100.0
    /// Flight time in simulated seconds.
    public var t = 0.0
    public var airborne = false, done = false, burning = false, fuelWarned = false
    public var mission: Mission? { weather.mission }
    /// Seconds held inside the proposal band.
    public var missionProgress = 0.0
    public var missionDone = false
    public var moment: FlightMoment?
    public var result: FlightResult?
    /// v122: riding the thermal in the last step (the arrows and the tag under the basket).
    public private(set) var inThermal = false
    /// v122: the tutorial's look at the landing field slows the flight to this share while the camera is away.
    public var slow = 1.0

    public init(weather: Weather, pax: Int, burners: Int = 1, turningVent: Bool = false, region: RegionID = .cap) {
        self.weather = weather
        self.pax = pax
        burnerPower = Burners.heat[clamp(burners, 1, 3) - 1]
        self.turningVent = turningVent
        var obs = FlightWorld.obstacles(for: weather)
        lines = FlightWorld.powerLines(for: weather)
        bristol = region.bristol ? BristolWorld.build(weather, obstacles: &obs, lines: lines) : nil
        obstacles = obs
        moment = FlightMoment.roll(weather)
    }

    /// v124: the fog hides the landing field while you're above its top.
    public var fieldHidden: Bool { weather.fog.map { alt >= $0.top && !done } ?? false }

    /// `briHit`: what a crash at x hit in Bristol.
    func bristolHit(_ x: Double) -> ObstacleKind? {
        guard let b = bristol else { return nil }
        if b.bridgeHeight(at: x) > 0 { return .bridge }
        guard let o = obstacles.filter({ abs(x - $0.x) < $0.w / 2 }).max(by: { $0.h < $1.h }) else { return nil }
        return o.kind == .plain ? .tree : o.kind
    }

    public var distanceToTarget: Double { abs(x - weather.target) }

    /// Advances by `dt` real seconds and returns what happened.
    public mutating func step(_ dt: Double) -> [Event] {
        guard !done else { return [] }
        var ev: [Event] = []
        inThermal = false
        let s = dt * FlightWorld.timeScale * slow
        if venting && airborne { heat -= 0.07 * s }
        if burning && fuel > 0 {
            heat += 0.05 * burnerPower * s
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
            let th = FlightWorld.terrainHeight(at: x, obstacles, lines: lines, bristol: bristol)
            if th > 4 && alt < th {
                hitWire = lines.contains { $0.wire(at: x) != nil }
                hit = hitWire ? nil : bristolHit(x)
                land(.crash)
                return ev + [.landed]
            }
            if alt <= 0 {
                alt = 0
                let before = missionDone
                land(-vy > (turningVent ? Burners.turningVentHardLanding : 2.6) ? .hard : nil)
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
                    if abs(x - m.x) < 65 && alt < 520 {
                        vy += Rules.thermalLift * s
                        inThermal = true
                        m.progress += dt
                        if m.progress > 2 { m.done = true; fuel = min(100, fuel + 15) }
                    }
                case .greet:
                    if abs(x - m.x) < 95 && abs(alt - m.alt) < 50 { m.progress += dt; if m.progress > 2 { m.done = true } } else { m.progress = 0 }
                case .photo:
                    if abs(x - m.x) < 70 && FlightMoment.photoBand.contains(alt) { m.progress += dt; if m.progress > 1.5 { m.done = true } }
                }
                if m.done { ev.append(.moment(m.kind)) }
            }
            moment = m
        }
        if airborne && alt > 0 && fuel <= 0 && !fuelWarned { fuelWarned = true; ev.append(.fuelOut) }
        // v124 `briAirTick`: a warning on the way in, a fine after three seconds inside
        if let a = weather.air, airborne {
            inAirspace = a.contains(x: x, alt: alt)
            if inAirspace {
                airspaceTime += dt
                if !airspaceWarned { airspaceWarned = true; ev.append(.airspaceWarning) }
                if airspaceTime > Airspace.seconds && !airspaceFined { airspaceFined = true; ev.append(.airspaceViolated) }
            } else {
                airspaceTime = 0
            }
        }
        return ev
    }

    mutating func land(_ q: FlightResult.Landing?) {
        done = true
        burning = false
        venting = false
        let dist = distanceToTarget
        let landing = q ?? (dist < FlightWorld.landingZone ? .perfect : dist < 260 ? .good : .far)
        if mission == .precision && dist < 40 && landing != .hard && landing != .crash { missionDone = true }
        result = FlightResult(landing: landing, distance: dist, mission: mission, missionDone: mission != nil && missionDone,
                              moment: moment?.done == true ? moment?.kind : nil)
        // v124: Bristol: where you came down (a field with sheep or cows, the tidal mud), and the airport's fine
        if let b = bristol, landing != .crash {
            result?.farm = b.pen(at: x)
            result?.mud = b.mud(at: x) ? true : nil
        }
        if airspaceFined { result?.airFine = true }
    }

    /// Cancel before take-off: passengers get refunds and compensation.
    public mutating func cancel() {
        guard !airborne, !done else { return }
        done = true
        burning = false
        result = FlightResult(landing: .cancel, mission: mission)
    }
}
