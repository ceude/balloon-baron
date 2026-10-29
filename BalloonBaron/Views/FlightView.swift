import SwiftUI
import BalloonBaronCore

// Port of the prototype's flight mode: startFlight, setBurn, updateFlight, missionDone, couple, land
// and the flight branch of draw().

private func fclamp(_ v: Double, _ lo: Double, _ hi: Double) -> Double { min(max(v, lo), hi) }

/// Fixed-size fonts for text drawn in the Canvas (the scene doesn't follow Dynamic Type).
private func sceneFont(_ size: CGFloat, _ weight: Font.Weight, condensed: Bool = false) -> Font {
    let name: String
    if condensed {
        name = weight == .heavy || weight == .black ? "BarlowCondensed-ExtraBold" : "BarlowCondensed-Bold"
    } else {
        name = weight == .bold ? "Barlow-Bold" : weight == .semibold ? "Barlow-SemiBold" : "Barlow-Regular"
    }
    return .custom(name, fixedSize: size)
}

/// Renders `**bold**` spans of a localized string, like the prototype's `<b>` tips.
private func richText(_ s: String, size: CGFloat) -> Text {
    var out = Text(verbatim: "")
    for (i, part) in s.components(separatedBy: "**").enumerated() where !part.isEmpty {
        out = out + Text(verbatim: part).font(Theme.font(size, i % 2 == 1 ? .bold : .regular))
    }
    return out
}

/// A heart or a confetti piece of the proposal celebration. Positions relative to the basket.
private struct Particle {
    var heart: Bool
    var x: Double, y: Double, vx: Double, vy: Double
    var life: Double, t: Double
    var size: Double, phase: Double
    var color: Color
    var rot: Double, w: Double
}

/// Everything about today's flight that doesn't change while flying.
private struct FlightLook {
    let colors: [String]
    let design: Design?
    let ad: Sponsor?
    let xl: Bool
    let region: RegionID
    let winter: Bool
    let layers: [Double]
    let target: Double
    let valley: Double
    let mission: Mission?
    let missionTitle: String
    let reward: Int
    let windText: [String]
    let zoneText: String
    let rewardPop: String
    let altLabel: String
    let vertLabel: String
    let fuelLabel: String
}

/// The running flight (`FL` in the prototype). A plain class: the TimelineView redraws every frame.
final class FlightModel {
    enum Tip { case tutorial, pax, fuel, vent, goal, wrong, still, near, lowFuel, airspace, airspaceFined }

    /// Shown once ever, the first time a flight leaves the ground.
    static let ventTipKey = "ventTip"

    var sim: FlightSim
    fileprivate let look: FlightLook
    var bg: [BackgroundBalloon]
    let pax: Int
    /// First flight: the tutorial tip disappears at take-off.
    let tutorial: Bool
    /// v111: your first own flights get the flying coach (`coachTick`).
    let coached: Bool
    /// v122.8: the very first own flight (the chimneys' red glow is only for it).
    let firstFlight: Bool
    private var coachAt: Double?
    private var coachTip: Tip?
    private var said: [Tip: Int] = [:]
    private var wrongT = 0.0, stillT = 0.0, lowFuel = false
    /// v111.2: the lean when crossing into a different wind (radians) and its speed; only the picture leans.
    private(set) var tilt = 0.0
    private var tiltV = 0.0
    /// Real seconds since the scene opened (`T`).
    var T = 0.0
    var last: Double?
    var driftDt = 0.0
    var skyHold = false
    var buttonHold = false
    /// Holding the parachute vent button.
    var ventHold = false
    private var ventOn = false
    var tip: Tip?
    var mdoneAt: Double?
    /// When the flight's moment (thermal, greeting, photo) was caught.
    var momentAt: Double?
    var celebAt: Double?
    var applauseAt: Double?
    fileprivate var fx: [Particle] = []
    var burnerOn = false
    var landedHandled = false
    var reported = false
    var onLanded: (() -> Void)?
    /// v121.2 (TestFlight): the flight stands still under the pause card.
    var paused = false

    // MARK: v122 tutorial (`tutFlightStart`, `tutFlightTick`)

    /// The first own flights show their steps: burner, wind layers, vent, the landing field, a chimney, the thermal.
    private(set) var tut = false
    private var tutDone: Set<String> = []
    /// Records a step (the store saves it and sends its telemetry signal).
    var onTutStep: ((String) -> Void)?
    /// The step on screen and when it came up.
    private(set) var tutK: String?
    private(set) var tutT0 = 0.0
    private var burnT = 0.0, windT = 0.0, ventT = 0.0, ventWait = 0.0
    /// A chimney ahead being pointed out (`st.ch`).
    struct TutChimney { let c: Obstacle; let dir: Double; let t0: Double }
    private(set) var tutCh: TutChimney?
    /// The camera's look at the landing field: when it started.
    private(set) var panT0: Double?
    /// Where the scene drew what the tutorial points at, this frame (`TUTC`), in screen points.
    struct TutScene {
        var cam: SceneCamera?
        var bal: (c: CGPoint, r: CGFloat)?
        var layers: CGRect?
        var field: CGRect?
        var chim: CGRect?
        var therm: CGRect?
    }
    var tutC = TutScene()

    func tutHas(_ k: String) -> Bool { tutDone.contains(k) }

    private func tutStep(_ k: String) {
        guard tutDone.insert(k).inserted else { return }
        onTutStep?(k)
    }

    private func tutShow(_ k: String) {
        if tutK != k { tutK = k; tutT0 = T }
    }

    private func tutEnd(_ k: String) {
        if tutK == k { tutK = nil }
    }

    /// "Skip": the whole tutorial ends.
    func tutSkip() {
        tut = false
        tutK = nil
        tutCh = nil
        panT0 = nil
        sim.slow = 1
    }

    private static func easeIO3(_ t: Double) -> Double {
        let t = fclamp(t, 0, 1)
        return t < 0.5 ? 4 * t * t * t : 1 - pow(-2 * t + 2, 3) / 2
    }

    /// How far the camera has turned to the landing field (0 … 1): 1.2 s there, 2 s on it, 1 s back.
    var tutPanK: Double {
        guard let p = panT0 else { return 0 }
        let t = T - p
        return t < 1.2 ? Self.easeIO3(t / 1.2) : t < 3.2 ? 1 : 1 - Self.easeIO3((t - 3.2) / 1)
    }

    /// The wind step lights the layers one after another for 2.4 s, then the one that blows hardest toward the field.
    var tutLayerLit: Int {
        let tt = tutK == "wind" ? T - tutT0 : 9
        let dx: Double = sim.weather.target - sim.x < 0 ? -1 : 1
        if tt < 2.4 { return 3 - Int(tt / 0.6) }
        let ls = look.layers
        var b = 0
        for (i, v) in ls.enumerated() where v * dx > ls[b] * dx { b = i }
        return b
    }

    /// The first chimney ahead, 40–300 m away, on screen and low enough to hit (its top at most 160 m below).
    private func tutChimney() -> TutChimney? {
        guard let cam = tutC.cam else { return nil }
        let f = sim
        let dir: Double = f.vx > 0 ? 1 : f.vx < 0 ? -1 : (f.weather.target - f.x < 0 ? -1 : 1)
        var best: Obstacle?
        var bd = 1e9
        for c in f.obstacles {
            let d = (c.x - f.x) * dir, X = cam.sx(c.x)
            if d > 40 && d < 300 && d < bd && f.alt < c.h + 160 && X > 20 && X < cam.size.width - 20 { best = c; bd = d }
        }
        return best.map { TutChimney(c: $0, dir: dir, t0: T) }
    }

    private func tutTick(_ dt: Double) {
        guard tut, !sim.done else { return }
        let dx = sim.weather.target - sim.x, side: Double = dx < 0 ? -1 : 1, toward = sim.vx * side
        if burning && sim.fuel > 0 { burnT += dt }
        if let p = panT0 {
            sim.slow = 0.25
            if T - p > 4.2 { panT0 = nil; sim.slow = 1; tutStep("field"); tutEnd("field") }
            return
        }
        if let ch = tutCh {
            let past = (sim.x - ch.c.x) * ch.dir > ch.c.w / 2 + 8
            if past || T - ch.t0 > 9 { tutStep("chimney"); tutEnd("chimney"); tutCh = nil }
            else if abs(ch.c.x - sim.x) > 450 { tutCh = nil; tutEnd("chimney") }
        }
        let th: FlightMoment? = sim.moment?.kind == .thermal && !tutHas("thermal") ? sim.moment : nil
        if let t = th, t.progress > 0.3 || t.done || (sim.x - t.x) * side > 160 { tutStep("thermal"); tutEnd("thermal") }
        var k: String?
        if !tutHas("burn") {
            k = "burn"
        } else if sim.airborne {
            // a chimney ahead comes first whenever it shows up
            if !tutHas("chimney") && tutCh == nil { tutCh = tutChimney() }
            if !tutHas("chimney") && tutCh != nil { k = "chimney" }
            else if let t = th, !tutHas("thermal"), abs(t.x - sim.x) < 420 { k = "thermal" }
            else if !tutHas("wind") { k = "wind" }
            else if !tutHas("vent") { ventWait += dt; if sim.alt >= 70 || ventWait > 6 { k = "vent" } }
            else if !tutHas("field") { k = "field" }
        }
        guard let k else { tutK = nil; return }
        if tip != .fuel { tip = nil } // one voice at a time: the coach waits
        tutShow(k)
        switch k {
        case "burn":
            if burnT >= 1 && sim.alt > 20 && sim.vy > 0 { tutStep("burn"); tutEnd("burn") }
        case "wind":
            if toward > 0.25 { windT += dt }
            if windT >= 2 { tutStep("wind"); tutEnd("wind") }
        case "vent":
            if sim.venting { ventT += dt }
            if ventT >= 0.5 { tutStep("vent"); tutEnd("vent") }
        case "field":
            panT0 = T
            sim.slow = 0.25
        default:
            break
        }
    }

    func pause() {
        guard !sim.done, !paused else { return }
        setHold(sky: false, button: false)
        setVent(false)
        paused = true
    }

    init(state s: GameState, weather w: Weather, pax: Int) {
        let fb = s.balloon(s.flagship)
        sim = FlightSim(weather: w, pax: pax, burners: fb?.burners ?? 1, turningVent: fb?.hasTurningVent ?? false, region: s.region)
        self.pax = pax
        tutorial = !s.tutorialDone
        coached = (s.selfFlights ?? 0) < Rules.coachFlights
        firstFlight = (s.selfFlights ?? 0) < 1
        tip = s.tutorialDone ? .pax : .tutorial
        bg = ScenePainter.backgroundBalloons(s)
        // Festivals pay half as much again for special requests.
        let reward = Int((Double(w.mission?.reward(for: fb?.size ?? .S) ?? 0) * (s.festival != nil ? Rules.festivalReward : 1) + 0.5).rounded(.down))
        look = FlightLook(
            colors: s.colors, design: fb.flatMap { s.design(of: $0) }, ad: fb?.ad, xl: fb?.size == .XL,
            region: s.region, winter: s.winter != nil, layers: w.layers, target: w.target, valley: w.valley,
            mission: w.mission, missionTitle: w.mission?.title ?? "", reward: reward,
            windText: w.layers.map { loc("flight.kmh", num(Int((abs($0) * 3.6).rounded()))) },
            zoneText: loc("flight.proposalZone"), rewardPop: loc("flight.missionPop", eur(reward)),
            altLabel: loc("flight.alt"), vertLabel: loc("flight.vert"), fuelLabel: loc("flight.fuel"))
        // v122: the tutorial's flight steps, up to the fifth own flight while some are left
        let flown = s.selfFlights ?? 0
        let done = Set(s.tutorial?.steps.keys.map { $0 } ?? [])
        tutDone = done
        tut = s.tutorialOn && flown < Rules.tutorialFlights && TutorialState.flightSteps.contains { !done.contains($0) }
        if tut {
            // The second own flight brings a thermal if the first had none, so the lesson isn't left to chance.
            if flown >= 1 && !done.contains("thermal") && sim.moment?.kind != .thermal {
                sim.moment = FlightMoment.tutorialThermal(w, k: Double.random(in: 0...1))
            }
            if !done.contains("burn") { tip = nil }
        }
    }

    var burning: Bool { skyHold || buttonHold }

    /// `setBurn(on)` for the sky and the button.
    func setHold(sky: Bool? = nil, button: Bool? = nil) {
        if let sky { skyHold = sky }
        if let button { buttonHold = button }
        if burning && !sim.done && sim.t > 1 && !sim.fuelWarned && !(coachTip != nil && T - (coachAt ?? -99) < 5) { tip = nil }
    }

    /// `setVent(on)`: hold the parachute vent open, once airborne.
    func setVent(_ on: Bool) {
        guard !sim.done else { return }
        ventHold = on
        sim.venting = on
    }

    /// One frame: `updateFlight(dt)` plus effects and sound.
    func advance(to date: Date) {
        let now = date.timeIntervalSinceReferenceDate
        let dt = last.map { min(0.05, max(0, now - $0)) } ?? 0
        last = now
        guard dt > 0, !paused else {
            if paused && burnerOn { burnerOn = false; SoundEngine.shared.burner(false) }
            return
        }
        T += dt
        driftDt += dt
        if !sim.done {
            sim.burning = burning
            for e in sim.step(dt) { handle(e) }
            // Crossing into a layer whose wind differs from the balloon's drift, the envelope (higher up, in the new
            // air first) is pushed ahead and the basket lags: a lean toward the relative wind on a soft spring.
            let rel = sim.alt > 3 ? FlightWorld.baseWind(at: sim.alt + 20, sim.weather) - sim.vx : 0
            let goal = min(max(rel * 0.028, -0.1), 0.1)
            tiltV += ((goal - tilt) * 14 - tiltV * 3.2) * dt
            tilt += tiltV * dt
            coachTick(dt)
            tutTick(dt)
        }
        stepFx(dt)
        if let a = applauseAt, T >= a {
            applauseAt = nil
            SoundEngine.shared.play(.applause)
        }
        let want = !sim.done && sim.burning && sim.fuel > 0
        if want != burnerOn {
            burnerOn = want
            SoundEngine.shared.burner(want)
            Haptics.burnerToggled(on: want)
        }
        if want { Haptics.burner(at: T) }
        let venting = !sim.done && sim.venting && sim.airborne
        if venting != ventOn {
            ventOn = venting
            if venting { Haptics.ventOpened() }
        }
        if venting && !want { Haptics.vent(at: T) }
    }

    private func handle(_ e: FlightSim.Event) {
        switch e {
        case .airborne:
            if tutorial { tip = nil }
            let d = UserDefaults.standard
            if tut {
                // v122: the tutorial's vent step teaches it
                d.set(true, forKey: Self.ventTipKey)
            } else if !d.bool(forKey: Self.ventTipKey) {
                d.set(true, forKey: Self.ventTipKey)
                tip = .vent
            } else if coached {
                say(.goal)
            }
        case .missionDone:
            mdoneAt = T
            SoundEngine.shared.play(.fanfare)
            Haptics.success()
            if look.mission == .proposal && !sim.done {
                celebAt = T
                spawnFx()
                applauseAt = T + 0.6
            }
        case .fuelOut:
            tip = .fuel
        case .airspaceWarning:
            // v124: the airport's airspace: a warning on the way in, then the fine is coming
            tip = .airspace
            SoundEngine.shared.play(.thud)
        case .airspaceViolated:
            tip = .airspaceFined
            Haptics.landed(.hard)
        case .moment:
            momentAt = T
            SoundEngine.shared.play(.coin)
            Haptics.coin()
        case .landed:
            tip = nil
            ventHold = false
            if tut {
                // v122: steps left over wait for the next flight
                tutK = nil
                panT0 = nil
                sim.slow = 1
                tutStep("first_landing")
            }
            if let q = sim.result?.landing, q == .hard || q == .crash { SoundEngine.shared.play(.thud) }
            if let q = sim.result?.landing { Haptics.landed(q) }
            if !landedHandled {
                landedHandled = true
                if let cb = onLanded { DispatchQueue.main.async(execute: cb) }
            }
        }
    }

    /// v111: the flying coach (`coachSay` / `coachTick`). A TestFlight player didn't see that the landing field was the
    /// goal, lost track of the wind layers and ran out of fuel; in your first flights Hezarfen says a word when it
    /// helps: drifting away, standing still, over the field. Low fuel is said on every flight.
    private func say(_ t: Tip) {
        // v122: the tutorial's line has the floor
        guard !(tut && tutK != nil) else { return }
        guard !sim.done, coachTip != t, (said[t] ?? 0) < 2, T - (coachAt ?? -99) >= 5 else { return }
        said[t, default: 0] += 1
        coachTip = t
        coachAt = T
        tip = t
    }

    private func coachTick(_ dt: Double) {
        guard sim.airborne, !sim.done else { return }
        if sim.fuel < 25 && !lowFuel {
            lowFuel = true
            coachAt = nil
            coachTip = nil
            say(.lowFuel)
        }
        if let a = coachAt, T - a > 6, coachTip != nil, tip == coachTip {
            tip = nil
            coachTip = nil
        }
        guard coached else { return }
        let dx = sim.weather.target - sim.x, toward = sim.vx * (dx < 0 ? -1 : 1)
        wrongT = toward < -0.3 && abs(dx) > 150 ? wrongT + dt : 0
        stillT = abs(toward) <= 0.3 && abs(dx) > 150 ? stillT + dt : 0
        // v121.12: the hint goes once it's no longer true
        if (coachTip == .wrong && wrongT == 0) || (coachTip == .still && stillT == 0) {
            if tip == coachTip { tip = nil }
            coachTip = nil
        }
        if abs(dx) < 260 && sim.alt > 40 { say(.near) }
        else if wrongT > 2.5 { say(.wrong) }
        else if stillT > 4 { say(.still) }
    }

    /// Kilometers to the landing field, for the goal tip.
    var fieldKm: String { (abs(sim.weather.target - sim.x) / 1000).formatted(.number.precision(.fractionLength(0...1))) }

    private func spawnFx() {
        func rnd(_ a: Double, _ b: Double) -> Double { Double.random(in: a...b) }
        fx = []
        let red = Color(hex: "#ff4f7b")
        for _ in 0..<22 {
            fx.append(Particle(heart: true, x: rnd(-8, 8), y: -10, vx: rnd(-14, 14), vy: rnd(-34, -18),
                               life: rnd(4, 5.5), t: -rnd(0.6, 3.5), size: rnd(8, 13),
                               phase: rnd(0, 6), color: red, rot: 0, w: 0))
        }
        let cols = ["#ff5e3a", "#ffc23d", "#ff6fa8", "#3ad0c0", "#ffffff", "#b79cff"]
        for i in 0..<60 {
            let delay = i < 30 ? rnd(0, 0.1) : rnd(0.6, 0.8)
            let col = Color(hex: cols.randomElement() ?? "#ffffff")
            fx.append(Particle(heart: false, x: 0, y: -12, vx: rnd(-70, 70), vy: rnd(-120, -45),
                               life: rnd(2.6, 3.6), t: -delay, size: 0, phase: 0,
                               color: col, rot: rnd(0, 6), w: rnd(3, 5)))
        }
    }

    private func stepFx(_ dt: Double) {
        guard celebAt != nil else { return }
        for i in fx.indices {
            fx[i].t += dt
            if fx[i].t < 0 || fx[i].t > fx[i].life { continue }
            if !fx[i].heart {
                fx[i].vy += 70 * dt
                fx[i].vx *= 0.985
            }
            fx[i].x += fx[i].vx * dt
            fx[i].y += fx[i].vy * dt
        }
    }

    /// The result card's first line (`land()` messages).
    func landingText(_ r: FlightResult) -> String {
        switch r.landing {
        case .perfect: return loc("flight.land.perfect")
        case .good: return loc("flight.land.good")
        case .far: return loc("flight.land.far", num(Int(r.distance.rounded())))
        case .hard: return loc("flight.land.hard")
        case .crash:
            if sim.hitWire { return loc("flight.land.crash.wire") }
            switch look.region {
            case .cap: return loc("flight.land.crash")
            case .abq: return loc("flight.land.crash.abq")
            case .lux: return loc("flight.land.crash.lux")
            case .bri: return loc("flight.hit.\((sim.hit ?? .tree).rawValue)")
            }
        case .cancel: return ""
        }
    }

    /// v124: Bristol's extra lines on the result card: the field with animals, the tidal mud, the airport.
    func bristolLines(_ r: FlightResult) -> [String] {
        var out: [String] = []
        if let a = r.farm { out.append(loc("flight.land.farm.\(a.rawValue)")) }
        if r.mud == true { out.append(loc("flight.land.mud")) }
        if r.airFine == true { out.append(loc("flight.land.airFine")) }
        return out
    }

    var missionTitle: String { look.missionTitle }
    var reward: Int { look.reward }
}

// MARK: - View

/// The player's own flight: full-screen scene, hold to burn, land on the field, then the day report.
struct FlightView: View {
    @Environment(GameStore.self) private var store
    @Environment(\.scenePhase) private var phase
    @State private var model: FlightModel?
    @State private var confirmAbort = false

    var body: some View {
        GeometryReader { geo in
            let ins = geo.safeAreaInsets
            let full = CGSize(width: geo.size.width + ins.leading + ins.trailing, height: geo.size.height + ins.top + ins.bottom)
            ZStack {
                Color(hex: "#1b1840")
                if let model {
                    FlightStage(model: model, insets: ins, size: full,
                                onAbort: { confirmAbort = true }, onReport: report)
                }
            }
            .ignoresSafeArea()
        }
        .overlay {
            if confirmAbort, let model { abortCard(model) }
        }
        .onAppear(perform: setup)
        .onDisappear { SoundEngine.shared.burner(false) }
        .onChange(of: phase) { _, p in if p != .active { model?.pause() } } // leaving the app pauses the flight
    }

    private func setup() {
        guard model == nil, let s = store.state, let w = s.weather else { return }
        let m = FlightModel(state: s, weather: w, pax: store.flightPax ?? 0)
        let st = store
        m.onLanded = { st.act { $0.state.tutorialDone = true } }
        // v122: steps are saved and signalled outside the frame that found them
        m.onTutStep = { k in DispatchQueue.main.async { st.tutStep(k) } }
        model = m
    }

    private func report() {
        guard let m = model, !m.reported else { return }
        m.reported = true
        SoundEngine.shared.burner(false)
        store.endDay(m.sim.result)
    }

    // MARK: confirmAbort()

    private func abortCard(_ m: FlightModel) -> some View {
        let refund = m.pax * (store.state?.price ?? 0)
        let comp = m.pax * Rules.cancelCompensation
        return ModalCard {
            CardText.title(loc("flight.abort.title"))
            CardText.lead(loc("flight.abort.lead", num(m.pax)))
            VStack(spacing: 5) {
                ledgerRow(loc("flight.abort.refund"), "−" + eur(refund))
                ledgerRow(loc("flight.abort.comp", eur(Rules.cancelCompensation)), "−" + eur(comp))
                ledgerRow(loc("flight.abort.rep"), "−" + starsValue(0.1))
                Rectangle().fill(Theme.ink).frame(height: 2).padding(.top, 4)
                ledgerRow(loc("flight.abort.total"), "−" + eur(comp), total: true).padding(.top, 4)
            }
            CardText.hint(loc("flight.abort.hint"))
            HStack(spacing: 10) {
                Button(loc("flight.abort.keep")) { confirmAbort = false }
                    .buttonStyle(ChunkyButtonStyle(kind: .ghost))
                Button(loc("flight.abort.confirm")) { abort(m) }
                    .buttonStyle(ChunkyButtonStyle(kind: .big))
            }
        }
    }

    private func ledgerRow(_ label: String, _ value: String, total: Bool = false) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text(label).font(Theme.font(14.5, total ? .bold : .regular)).foregroundStyle(Theme.ink)
            Spacer(minLength: 4)
            Text(value).font(Theme.font(total ? 22 : 17, .bold, condensed: true)).foregroundStyle(Theme.red)
        }
    }

    private func abort(_ m: FlightModel) {
        confirmAbort = false
        guard !m.sim.airborne, !m.sim.done, !m.reported else { return }
        m.sim.cancel()
        m.setHold(sky: false, button: false)
        m.reported = true
        SoundEngine.shared.burner(false)
        store.endDay(m.sim.result)
    }
}

/// The animated scene plus the on-screen controls (`#burn`, `#abort`, `#tip`).
private struct FlightStage: View {
    @Environment(GameStore.self) private var store
    let model: FlightModel
    let insets: EdgeInsets
    let size: CGSize
    let onAbort: () -> Void
    let onReport: () -> Void

    var body: some View {
        TimelineView(.animation) { tl in
            let _ = model.advance(to: tl.date)
            ZStack {
                scene(tl.date)
                controls
                tipLayer
                resultLayer
                pauseLayer
            }
            .tutorialHost(minLineY: insets.top + 60, alive: { model.tut }, frame: tutFrame, onSkip: {
                model.tutSkip()
                store.skipTutorial()
            })
        }
    }

    // MARK: v122 tutorial

    /// The flight's step on screen (`tutFlightTick`'s `tutShow`): what to light, where the arrow points.
    private func tutFrame(_ sp: TutSpots) -> TutFrame? {
        let m = model, C = m.tutC
        guard m.tut, let k = m.tutK, !m.sim.done, !m.paused else { return nil }
        let bal = C.bal.map { TutHole.circle($0.c, $0.r) }
        // Under the flight panel and the pause button, so it never covers the controls.
        let lineY = insets.top + 6 + 4 + 92 + 52
        // In flight the dark lifts after 2.5 s (to 20%) so the chimneys stay visible.
        let dim = 0.42 * (1 - 0.8 * fclamp(m.T - m.tutT0 - 2.5, 0, 1))
        func arrowBy(_ dy: CGFloat, _ dir: TutArrow.Dir) -> TutArrow?? {
            guard let b = C.bal else { return .some(nil) }
            return .some(TutArrow(at: CGPoint(x: b.c.x + b.r + 22, y: b.c.y + dy), dir: dir))
        }
        switch k {
        case "burn":
            return TutFrame(key: k, holes: [sp.hole("burn", pad: 8, round: true), bal].compactMap { $0 }, arrow: arrowBy(0, .up),
                            line: loc("tut.burn"), dim: dim, lineY: lineY)
        case "wind":
            let lit = m.tutLayerLit
            var arrow: TutArrow?? = .some(nil)
            if let cam = C.cam { arrow = .some(TutArrow(at: CGPoint(x: 146, y: cam.sy(Rules.windCenters[lit])), dir: .left)) }
            return TutFrame(key: k, holes: [C.layers.map { TutHole(rect: $0, radius: 18) }, bal].compactMap { $0 }, arrow: arrow,
                            line: loc("tut.wind"), dim: dim, lineY: lineY)
        case "vent":
            return TutFrame(key: k, holes: [sp.hole("vent", pad: 8, round: true), bal].compactMap { $0 }, arrow: arrowBy(10, .down),
                            line: loc("tut.vent"), dim: dim, lineY: lineY)
        case "field":
            return TutFrame(key: k, holes: [C.field.map { TutHole(rect: $0, radius: 16) }].compactMap { $0 }, line: loc("tut.field"), dim: dim, lineY: lineY)
        case "chimney":
            return TutFrame(key: k, holes: [C.chim.map { TutHole(rect: $0, radius: 14) }].compactMap { $0 }, line: loc("tut.chimney"), dim: dim, lineY: lineY)
        case "thermal":
            return TutFrame(key: k, holes: [C.therm.map { TutHole(rect: $0, radius: 14) }].compactMap { $0 }, line: loc("tut.thermal"), dim: dim, lineY: lineY)
        default:
            return nil
        }
    }

    private func scene(_ date: Date) -> some View {
        let top = insets.top + 6
        let m = model
        return Canvas { ctx, sz in
            FlightPainter.draw(&ctx, size: sz, top: top, m: m, date: date)
        }
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in if !m.skyHold { m.setHold(sky: true) } }
                .onEnded { _ in m.setHold(sky: false) }
        )
        // The burner button carries the altitude and fuel for VoiceOver.
        .accessibilityHidden(true)
    }

    // MARK: Pause (v121.2)

    /// A round glass button under the flight panel, and the "Paused" card over the frozen flight.
    @ViewBuilder private var pauseLayer: some View {
        let m = model
        if m.paused && !m.sim.done {
            ModalCard {
                CardText.title(loc("flight.pause.title"))
                CardText.lead(loc("flight.pause.lead", loc("flight.meters", num(Int(m.sim.alt.rounded()))),
                                  (m.sim.fuel / 100).formatted(.percent.precision(.fractionLength(0)))))
                HStack(spacing: 10) {
                    SoundSettingsButton()
                        .background(Color(hex: "#f1edf8"), in: RoundedRectangle(cornerRadius: 14))
                    Button(loc("flight.pause.resume")) { m.paused = false }
                        .buttonStyle(ChunkyButtonStyle(kind: .big))
                }
            }
        } else if !m.sim.done {
            Button {
                SoundEngine.shared.play(.click)
                m.pause()
            } label: {
                Image(systemName: "pause.fill")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 38, height: 38)
                    .background(Theme.glass, in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(loc("flight.pause.a11y"))
            .padding(.top, insets.top + 6 + 4 + 92 + 8)
            .padding(.trailing, max(12, insets.trailing))
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
        }
    }

    // MARK: Buttons

    @ViewBuilder private var controls: some View {
        if !model.sim.done {
            HStack(alignment: .bottom) {
                // Once airborne the cancel button gives way to the parachute vent (`#vent`).
                if model.sim.airborne { ventButton } else { abortButton }
                Spacer(minLength: 8)
                burnButton
            }
            .padding(.leading, max(16, insets.leading))
            .padding(.trailing, max(16, insets.trailing))
            .padding(.bottom, max(22, insets.bottom))
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        }
    }

    private var abortButton: some View {
        let air = model.sim.airborne
        return Button(air ? loc("flight.inAir") : loc("flight.abort")) {
            SoundEngine.shared.play(.click)
            onAbort()
        }
        .buttonStyle(AbortButtonStyle())
        .disabled(air)
    }

    /// `#vent`: a round white button bottom-left; hold to open the parachute vent and sink fast.
    private var ventButton: some View {
        let on = model.ventHold
        let m = model
        return Text(loc("flight.vent"))
            .font(Theme.font(17, .heavy, condensed: true))
            .foregroundStyle(Theme.ink)
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            .padding(6)
            .frame(width: 76, height: 76)
            .background(Circle().fill(Color.white))
            .background(Circle().fill(Color.black.opacity(0.3)).offset(y: on ? 1 : 6))
            .background(Circle().fill(Color(red: 90 / 255, green: 169 / 255, blue: 230 / 255).opacity(on ? 0.45 : 0)).padding(-7))
            .compositingGroup()
            .offset(y: on ? 5 : 0)
            .contentShape(Circle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { v in
                        // pointerleave: sliding off the button lets go.
                        let dx = v.location.x - 38, dy = v.location.y - 38
                        let inside = dx * dx + dy * dy < 52 * 52
                        if inside != m.ventHold { m.setVent(inside) }
                    }
                    .onEnded { _ in m.setVent(false) }
            )
            .accessibilityElement(children: .ignore)
            .tutSpot("vent")
            .accessibilityLabel(loc("flight.vent.a11y"))
            .accessibilityHint(loc("a11y.flight.ventHint"))
            .accessibilityAddTraits(on ? [.isButton, .isSelected] : [.isButton])
            .accessibilityAction { m.setVent(!m.ventHold) }
    }

    private var burnButton: some View {
        let on = model.burning
        let m = model
        return Text(loc("flight.burn"))
            .font(Theme.font(18, .heavy, condensed: true))
            .foregroundStyle(.white)
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            .padding(6)
            .frame(width: 96, height: 96)
            .background(Circle().fill(Theme.coral))
            .background(Circle().fill(Color(hex: "#d9411f")).offset(y: on ? 2 : 7))
            .background(Circle().fill(Color(red: 1, green: 194 / 255, blue: 61 / 255).opacity(on ? 0.45 : 0)).padding(-8))
            .compositingGroup()
            .shadow(color: .black.opacity(on ? 0 : 0.3), radius: 12, y: 10)
            .offset(y: on ? 5 : 0)
            .contentShape(Circle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { v in
                        // pointerleave: sliding off the button lets go.
                        let dx = v.location.x - 48, dy = v.location.y - 48
                        let inside = dx * dx + dy * dy < 64 * 64
                        if inside != m.buttonHold { m.setHold(button: inside) }
                    }
                    .onEnded { _ in m.setHold(button: false) }
            )
            // VoiceOver can't press and hold: double-tapping switches the burner on and off, and the value reads
            // the panel's altitude (to 10 m, so it doesn't change every frame) and fuel.
            .accessibilityElement(children: .ignore)
            .tutSpot("burn")
            .accessibilityLabel(loc("intro.burn.a11y"))
            .accessibilityValue(loc("a11y.flight.status", num(Int((m.sim.alt / 10).rounded()) * 10), percent(max(0, m.sim.fuel) / 100)))
            .accessibilityHint(loc("a11y.flight.burnHint"))
            .accessibilityAddTraits(on ? [.isButton, .isSelected] : [.isButton])
            .accessibilityAction { m.setHold(button: !m.buttonHold) }
    }

    // MARK: Tips

    @ViewBuilder private var tipLayer: some View {
        if let t = model.tip, !model.sim.done {
            // v111.1: up in the sky left of the flight panel, so it never covers the balloon or the landing field.
            richText(tipText(t), size: 13)
                .foregroundColor(Theme.ink)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .frame(width: max(170, min(320, size.width - 180)), alignment: .leading)
                .background(Color.white, in: RoundedRectangle(cornerRadius: 14))
                .compositingGroup()
                .shadow(color: .black.opacity(0.25), radius: 10, y: 6)
                .allowsHitTesting(false)
                .padding(.leading, max(16, insets.leading))
                .padding(.top, insets.top + 10)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }

    private func tipText(_ t: FlightModel.Tip) -> String {
        switch t {
        case .tutorial: return loc("flight.tip.tutorial")
        case .pax:
            // v124: Bristol's fog and airspace are named under the passengers line
            let w = model.sim.weather
            return [loc("flight.tip.pax", num(model.pax)), w.fog != nil ? loc("flight.tip.fog") : nil, w.air != nil ? loc("flight.tip.air") : nil]
                .compactMap { $0 }.joined(separator: " ")
        case .fuel: return loc("flight.tip.fuel")
        case .vent: return loc("flight.tip.vent")
        case .goal: return loc("flight.coach.goal", model.fieldKm)
        case .wrong: return loc("flight.coach.wrong")
        case .still: return loc("flight.coach.still")
        case .near: return loc("flight.coach.near")
        case .lowFuel: return loc("flight.coach.lowFuel")
        case .airspace: return loc("flight.tip.airspace", num(Int(model.sim.weather.air?.floor ?? 0)))
        case .airspaceFined: return loc("flight.tip.airspaceFined")
        }
    }

    // MARK: Result (`#tip.wide` after land())

    @ViewBuilder private var resultLayer: some View {
        if let r = model.sim.result, r.landing != .cancel {
            resultCard(r)
                .frame(width: max(200, min(420, size.width - 32)))
                .padding(.bottom, max(20, insets.bottom))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        }
    }

    private func resultCard(_ r: FlightResult) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            richText(model.landingText(r), size: 14.5)
                .foregroundColor(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)
            ForEach(model.bristolLines(r), id: \.self) { l in
                richText(l, size: 14.5).foregroundColor(Theme.ink).fixedSize(horizontal: false, vertical: true)
            }
            if r.mission != nil { missionLine(r) }
            Button(loc("flight.dayReport")) {
                SoundEngine.shared.play(.click)
                onReport()
            }
            .buttonStyle(ChunkyButtonStyle(kind: .big))
            .padding(.top, 8)
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 18))
        .compositingGroup()
        .shadow(color: .black.opacity(0.25), radius: 10, y: 6)
    }

    private func missionLine(_ r: FlightResult) -> some View {
        let title = model.missionTitle
        var line = Text(verbatim: loc("flight.missionFail", title)).font(Theme.font(14.5)).foregroundColor(Theme.ink2)
        if r.missionDone {
            let ok = Text(verbatim: loc("flight.missionOk", title)).font(Theme.font(14.5, .bold)).foregroundColor(Theme.green)
            let pay = Text(verbatim: " +" + eur(model.reward)).font(Theme.font(14.5)).foregroundColor(Theme.ink)
            line = ok + pay
        }
        return line.fixedSize(horizontal: false, vertical: true)
    }
}

/// `#abort`: white pill bottom-left; faded once airborne.
private struct AbortButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        AbortBody(configuration: configuration)
    }

    private struct AbortBody: View {
        let configuration: ButtonStyleConfiguration
        @Environment(\.isEnabled) private var enabled

        var body: some View {
            let pressed = configuration.isPressed && enabled
            return configuration.label
                .font(Theme.font(18, .bold, condensed: true))
                .foregroundStyle(Theme.ink)
                .lineLimit(1)
                .padding(.horizontal, 18)
                .frame(height: 54)
                .background(RoundedRectangle(cornerRadius: 16).fill(Color.white))
                .background(DepthBand(radius: 16, drop: pressed ? 1 : 5).fill(Color.black.opacity(enabled ? 0.3 : 0)))
                .offset(y: pressed ? 4 : 0)
                .opacity(enabled ? 1 : 0.5)
        }
    }
}

// MARK: - Drawing

/// The flight branch of the prototype's `draw()`.
private enum FlightPainter {
    static func draw(_ ctx: inout GraphicsContext, size: CGSize, top: CGFloat, m: FlightModel, date: Date) {
        let f = m.sim, look = m.look
        let p = fclamp(f.t / 420, 0, 1) * 0.85 + 0.1
        let groundY = size.height * 0.86, topY = top + 34
        // v122: the tutorial's camera turns to the landing field for a moment
        let cam = SceneCamera(size: size, groundY: groundY, topY: topY, focusX: f.x + (look.target - f.x) * m.tutPanK)
        m.tutC.cam = cam
        if m.tut {
            let X0 = cam.sx(look.target - 85), X1 = cam.sx(look.target + 85)
            m.tutC.field = CGRect(x: X0, y: cam.sy(150), width: X1 - X0, height: groundY + 12 - cam.sy(150))
        }
        if m.driftDt > 0 {
            ScenePainter.drift(&m.bg, weather: f.weather, cam: cam, dt: m.driftDt, time: m.T, inFlight: true)
            m.driftDt = 0
        }
        let vh = ScenePainter.scenery(&ctx, cam: cam, p: p, region: look.region, winter: look.winter, time: m.T,
                                      background: m.bg, inFlight: true)
        if look.mission == .valley { valleyZone(&ctx, cam: cam, vx: look.valley) }
        if let b = f.bristol { BristolPainter.world(&ctx, cam: cam, b, p: p, time: m.T) } // v124
        // v124: in Bristol's fog the field (flags, glow, trailer) shows only once you're under the fog's top
        if !f.fieldHidden {
            ScenePainter.landingField(&ctx, cam: cam, target: look.target, p: p)
            fieldColumn(&ctx, cam: cam, target: look.target)
        }
        let lx = cam.sx(FlightWorld.launchX)
        ScenePainter.rect(&ctx, lx - 40, groundY - 1, 80, 4, ScenePainter.mix("#5c4a3a", "#b9996e", p))
        let chim = m.tutK == "chimney"
        var basket: (x: Double, alt: Double)?
        // v122.1/v122.8: the red glow near a chimney only on the very first own flight; once learned it stays out of the way
        if f.airborne && !f.done && m.firstFlight { basket = (x: f.x, alt: f.alt) }
        m.tutC.chim = ScenePainter.obstacles(&ctx, cam: cam, f.obstacles, region: look.region, p: p,
                                             basket: basket, ringAll: chim,
                                             pointed: m.tutCh?.c, label: chim ? loc("flight.chimneyLabel") : nil)
        ScenePainter.powerLines(&ctx, cam: cam, f.lines, p: p)
        if look.region == .bri {
            BristolPainter.overlay(&ctx, cam: cam, weather: f.weather, alt: f.alt, inside: f.inAirspace, done: f.done, time: m.T,
                                   airLabel: loc("flight.airspaceLabel", num(Int(f.weather.air?.floor ?? 0))),
                                   fogLabel: loc("flight.fogLabel", num(Int(f.weather.fog?.top ?? 0))))
        }
        let PR = max(12, vh * 0.065)
        windPills(&ctx, cam: cam, m: m)
        let R = PR * 0.75 * (look.xl ? 1.3 : 1)
        let bx = cam.sx(f.x), by = cam.sy(f.alt), burn = f.burning && f.fuel > 0
        m.tutC.bal = (CGPoint(x: bx, y: by - R * 1.5), R * 2.1) // the tutorial's hole around the balloon
        // The basket swings a little under the envelope (v110), more while the burner roars; still on the ground.
        let pivot = by - R * 1.9
        let sway = (sin(m.T * 1.1) * 0.6 + sin(m.T * 0.43 + 1) * 0.4) * (0.03 + (burn ? 0.015 : 0)) * fclamp(f.alt / 20, 0, 1)
        var bc = ctx
        bc.translateBy(x: bx, y: pivot)
        bc.rotate(by: .radians(sway + m.tilt))
        bc.translateBy(x: -bx, y: -pivot)
        if let design = look.design {
            ScenePainter.designBalloon3d(&bc, x: bx, y: by, r: R, colors: look.colors, burn: burn,
                                         ad: look.ad, design: design, region: look.region)
        } else {
            // The flagship is drawn in full volume, like the app icon; a workshop design gets the same volume.
            ScenePainter.balloon3d(&bc, x: bx, y: by, r: R, colors: look.colors, burn: burn,
                                   ad: look.ad, region: look.region)
        }
        if let c = m.celebAt { celebration(&ctx, m: m, bx: bx, by: by, r: R, ct: m.T - c) }
        liveWind(&ctx, m: m, bx: bx, y: max(top + 11, pivot - R * 1.2 - 12))
        fieldPointer(&ctx, cam: cam, m: m, top: top, pr: PR)
        missionGuides(&ctx, cam: cam, m: m)
        moment(&ctx, cam: cam, top: top, r: PR, m: m)
        if f.inThermal && !f.done { thermalRide(&ctx, bx: bx, by: by, T: m.T) }
        missionBanner(&ctx, width: size.width, top: top, m: m)
        panel(&ctx, width: size.width, top: top, m: m)
    }

    static func rrect(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ r: CGFloat) -> Path {
        Path(roundedRect: CGRect(x: x, y: y, width: max(0, w), height: max(0, h)), cornerRadius: min(r, max(0, w) / 2, max(0, h) / 2))
    }

    static func hline(_ ctx: inout GraphicsContext, y: CGFloat, width: CGFloat, color: Color, lineWidth: CGFloat, dash: [CGFloat]) {
        var l = Path()
        l.move(to: CGPoint(x: 0, y: y))
        l.addLine(to: CGPoint(x: width, y: y))
        ctx.stroke(l, with: .color(color), style: StrokeStyle(lineWidth: lineWidth, dash: dash))
    }

    /// The flight's small moment: a thermal column to ride, a neighbouring balloon to wave to, a photo spot.
    static func moment(_ ctx: inout GraphicsContext, cam: SceneCamera, top: CGFloat, r PR: CGFloat, m: FlightModel) {
        guard let mo = m.sim.moment else { return }
        let T = m.T, gy = cam.groundY
        switch mo.kind {
        case .thermal:
            // v122: a clearer column: a warmer glow, dashed edges where it starts lifting you, rising chevrons
            let X = cam.sx(mo.x), wv = cam.sx(mo.x + 65) - X, y0 = cam.sy(520), hh = gy - y0
            let warm = Color(red: 1, green: 200 / 255, blue: 120 / 255)
            let g = Gradient(colors: [warm.opacity(0), warm.opacity(mo.done ? 0.12 : 0.38), warm.opacity(0)])
            ctx.fill(Path(CGRect(x: X - wv, y: y0, width: wv * 2, height: hh)),
                     with: .linearGradient(g, startPoint: CGPoint(x: X - wv, y: 0), endPoint: CGPoint(x: X + wv, y: 0)))
            if !mo.done {
                var edges = Path()
                edges.move(to: CGPoint(x: X - wv, y: gy)); edges.addLine(to: CGPoint(x: X - wv, y: y0))
                edges.move(to: CGPoint(x: X + wv, y: gy)); edges.addLine(to: CGPoint(x: X + wv, y: y0))
                ctx.stroke(edges, with: .color(Color(red: 1, green: 225 / 255, blue: 170 / 255).opacity(0.6)),
                           style: StrokeStyle(lineWidth: 1.5, dash: [6, 7], dashPhase: CGFloat(-T * 30)))
            }
            for i in 0..<9 {
                let yy = gy - CGFloat((T * 55 + Double(i) * Double(hh) / 9).truncatingRemainder(dividingBy: Double(max(1, hh))))
                let xx = X + CGFloat(sin(Double(i) * 2.3)) * wv * 0.45
                let a = fclamp(Double(gy - yy) / 40, 0, 1) * fclamp(Double(yy - y0) / 40, 0, 1)
                var chev = Path()
                chev.move(to: CGPoint(x: xx - 6, y: yy + 5))
                chev.addLine(to: CGPoint(x: xx, y: yy - 1))
                chev.addLine(to: CGPoint(x: xx + 6, y: yy + 5))
                ctx.stroke(chev, with: .color(.white.opacity((mo.done ? 0.35 : 0.75) * a)), style: StrokeStyle(lineWidth: 2.2, lineCap: .round))
            }
            if !mo.done {
                ctx.draw(Text(loc("flight.thermalColumn")).font(sceneFont(14, .heavy, condensed: true)).foregroundColor(.white),
                         at: CGPoint(x: X, y: y0 - 6), anchor: .bottom)
            }
            m.tutC.therm = CGRect(x: X - wv - 6, y: y0 - 26, width: wv * 2 + 12, height: hh + 26)
        case .greet:
            let X = cam.sx(mo.x), Y = cam.sy(mo.alt + sin(T) * 5)
            let cols = FlightMoment.greetColors[mo.colors % FlightMoment.greetColors.count]
            ScenePainter.balloon(&ctx, x: X, y: Y, r: PR * 0.62, colors: cols, burn: T.truncatingRemainder(dividingBy: 4) < 0.4, alpha: 0.36, time: T)
            if mo.done, let at = m.momentAt, T - at < 3 {
                badge(&ctx, "hand.wave.fill", x: X + PR * 0.7, y: Y - PR * 1.9, a: min(1, (3 - (T - at)) / 0.5))
            }
        case .photo:
            if !mo.done {
                let X = cam.sx(mo.x), half = cam.sx(mo.x + 70) - X
                let y0 = cam.sy(FlightMoment.photoBand.upperBound), y1 = cam.sy(FlightMoment.photoBand.lowerBound)
                ctx.stroke(Path(CGRect(x: X - half, y: y0, width: half * 2, height: y1 - y0)), with: .color(.white.opacity(0.85)),
                           style: StrokeStyle(lineWidth: 2, dash: [6, 5]))
                badge(&ctx, "camera.fill", x: X, y: y0 - 20, a: 1)
            }
        }
        guard mo.done, let at = m.momentAt else { return }
        if mo.kind == .photo && T - at < 0.35 {
            ctx.fill(Path(CGRect(origin: .zero, size: cam.size)), with: .color(.white.opacity(0.85 * (1 - (T - at) / 0.35))))
        }
        if T - at < 3.2 {
            let a = min(1, (3.2 - (T - at)) / 0.5)
            var c = ctx
            c.opacity = a
            let text = c.resolve(Text(loc("flight.moment.\(mo.kind.rawValue)")).font(sceneFont(16, .heavy, condensed: true)).foregroundColor(.white))
            let sz = text.measure(in: CGSize(width: cam.size.width - 32, height: 60))
            let w = sz.width + 28, x = cam.size.width / 2
            c.fill(rrect(x - w / 2, top + 150, w, 32, 16), with: .color(Color(red: 20 / 255, green: 120 / 255, blue: 90 / 255).opacity(0.92)))
            c.draw(text, at: CGPoint(x: x, y: top + 166), anchor: .center)
        }
    }

    /// v122: riding a thermal: rising chevrons under the basket and a small orange tag, so the lift is plain to see.
    static func thermalRide(_ ctx: inout GraphicsContext, bx: CGFloat, by: CGFloat, T: Double) {
        var c = ctx
        c.addFilter(.shadow(color: .black.opacity(0.35), radius: 2))
        for i in 0..<3 {
            let ph = (T * 1.6 + Double(i) / 3).truncatingRemainder(dividingBy: 1), yy = by + 34 - CGFloat(ph) * 26
            var chev = Path()
            chev.move(to: CGPoint(x: bx - 8, y: yy + 6))
            chev.addLine(to: CGPoint(x: bx, y: yy - 1))
            chev.addLine(to: CGPoint(x: bx + 8, y: yy + 6))
            c.stroke(chev, with: .color(Color(hex: "#ffd27a").opacity(sin(ph * .pi))),
                     style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
        }
        let label = ctx.resolve(Text(loc("flight.thermalTag")).font(sceneFont(13, .heavy, condensed: true)).foregroundColor(.white))
        let tw = label.measure(in: CGSize(width: 200, height: 40)).width + 16, tx = bx + 16, ty = by + 6
        ctx.fill(rrect(tx, ty - 10, tw, 20, 10), with: .color(Color(red: 214 / 255, green: 120 / 255, blue: 30 / 255).opacity(0.92)))
        ctx.draw(label, at: CGPoint(x: tx + 8, y: ty), anchor: .leading)
    }

    /// A small round badge with a drawn icon.
    static func badge(_ ctx: inout GraphicsContext, _ symbol: String, x: CGFloat, y: CGFloat, a: Double) {
        var c = ctx
        c.opacity = a
        c.fill(Path(ellipseIn: CGRect(x: x - 15, y: y - 15, width: 30, height: 30)), with: .color(Color(red: 1, green: 250 / 255, blue: 243 / 255).opacity(0.95)))
        let img = c.resolve(Image(systemName: symbol))
        var ic = c
        ic.addFilter(.colorMultiply(Theme.ink))
        ic.draw(img, in: CGRect(x: x - 9, y: y - 9, width: 18, height: 18))
    }

    /// Valley mission: shaded zone below 150 m with two flags.
    static func valleyZone(_ ctx: inout GraphicsContext, cam: SceneCamera, vx: Double) {
        let gy = cam.groundY, x0 = cam.sx(vx - 60), x1 = cam.sx(vx + 60), y0 = cam.sy(150)
        ScenePainter.rect(&ctx, x0, y0, x1 - x0, gy - y0, Color(red: 1, green: 194 / 255, blue: 61 / 255).opacity(0.16))
        for fx in [vx - 60, vx + 60] {
            let X = cam.sx(fx)
            var pole = Path()
            pole.move(to: CGPoint(x: X, y: gy))
            pole.addLine(to: CGPoint(x: X, y: gy - 26))
            ctx.stroke(pole, with: .color(Color(hex: "#2a1a14")), lineWidth: 1.5)
            var fl = Path()
            fl.move(to: CGPoint(x: X, y: gy - 26))
            fl.addLine(to: CGPoint(x: X + 12, y: gy - 21))
            fl.addLine(to: CGPoint(x: X, y: gy - 16))
            fl.closeSubpath()
            ctx.fill(fl, with: .color(Theme.sun))
        }
    }

    /// The four wind-layer pills on the left with arrow and speed.
    static func windPills(_ ctx: inout GraphicsContext, cam: SceneCamera, m: FlightModel) {
        let alt = m.sim.alt, layers = m.look.layers
        var tagW: CGFloat = 58
        for i in 0..<min(4, layers.count, m.look.windText.count) {
            let v = layers[i], band = FlightWorld.bands[i]
            let y = cam.sy(Rules.windCenters[i])
            let active = alt >= band.lowerBound && alt < band.upperBound
            if i > 0 {
                let ly = cam.sy(band.lowerBound)
                hline(&ctx, y: ly, width: cam.size.width, color: .white.opacity(0.42), lineWidth: 1.5, dash: [8, 6])
                ctx.draw(Text(verbatim: loc("flight.lineAlt", num(Int(band.lowerBound)))).font(sceneFont(11, .bold, condensed: true))
                            .foregroundColor(.white.opacity(0.75)), at: CGPoint(x: cam.size.width - 10, y: ly - 4), anchor: .bottomTrailing)
            }
            let len = CGFloat(12 + abs(v) * 5), x0: CGFloat = 14, dir: CGFloat = v < 0 ? -1 : 1
            let ax0 = dir > 0 ? x0 : x0 + len, ax1 = dir > 0 ? x0 + len : x0
            ctx.fill(rrect(6, y - 13, 112, 26, 13), with: .color(.white.opacity(active ? 0.95 : 0.35)))
            let c = active ? Theme.coral : Theme.ink
            var shaft = Path()
            shaft.move(to: CGPoint(x: ax0, y: y))
            shaft.addLine(to: CGPoint(x: ax1, y: y))
            ctx.stroke(shaft, with: .color(c), style: StrokeStyle(lineWidth: 3, lineCap: .round))
            var head = Path()
            head.move(to: CGPoint(x: ax1 + dir * 2, y: y))
            head.addLine(to: CGPoint(x: ax1 - dir * 5, y: y - 5))
            head.addLine(to: CGPoint(x: ax1 - dir * 5, y: y + 5))
            head.closeSubpath()
            ctx.fill(head, with: .color(c))
            let label = Text(verbatim: m.look.windText[i]).font(sceneFont(13, .bold, condensed: true)).foregroundColor(Theme.ink)
            ctx.draw(label, at: CGPoint(x: 70, y: y), anchor: .leading)
            // v122: the wind step lights the layers one by one, then marks the one that blows toward the field
            if m.tutK == "wind" && i == m.tutLayerLit {
                let pick = m.T - m.tutT0 >= 2.4
                let col = pick ? Color(hex: "#22a45d") : Color(hex: "#ffd27a")
                var g = ctx
                g.addFilter(.shadow(color: col, radius: 5))
                g.stroke(rrect(4, y - 15, 116, 30, 15), with: .color(col), lineWidth: 3.5)
                if pick {
                    let lbl = ctx.resolve(Text(loc("flight.toTarget")).font(sceneFont(13, .heavy, condensed: true)).foregroundColor(.white))
                    let w = max(58, lbl.measure(in: CGSize(width: 200, height: 40)).width + 18)
                    ctx.fill(rrect(124, y - 11, w, 22, 11), with: .color(col))
                    ctx.draw(lbl, at: CGPoint(x: 124 + w / 2, y: y), anchor: .center)
                    tagW = w
                }
            }
        }
        let pick = m.tutK == "wind" && m.T - m.tutT0 >= 2.4
        m.tutC.layers = CGRect(x: 1, y: cam.sy(Rules.windCenters[3]) - 19, width: pick ? 128 + tagW : 124,
                               height: cam.sy(Rules.windCenters[0]) - cam.sy(Rules.windCenters[3]) + 38)
    }

    // MARK: Proposal celebration

    static func celebration(_ ctx: inout GraphicsContext, m: FlightModel, bx: CGFloat, by: CGFloat, r R: CGFloat, ct: Double) {
        if ct < 14 { couple(&ctx, x: bx, rim: by - R * 0.32, r: R, t: ct) }
        let oy = by - R * 0.4
        for q in m.fx where q.t >= 0 && q.t <= q.life {
            var c = ctx
            c.opacity = fclamp(1 - q.t / q.life, 0, 1)
            if q.heart {
                let hx = bx + CGFloat(q.x + sin(m.T * 3 + q.phase) * 4)
                ScenePainter.heart(&c, hx, oy + CGFloat(q.y), CGFloat(q.size), q.color)
            } else {
                c.translateBy(x: bx + CGFloat(q.x), y: oy + CGFloat(q.y))
                c.rotate(by: .radians(q.rot + q.t * 8))
                let w = CGFloat(q.w)
                ScenePainter.rect(&c, -w / 2, -w / 4, w, w / 2, q.color)
            }
        }
    }

    /// `couple()`: silhouettes in the basket; he kneels with the ring, then they hug.
    static func couple(_ ctx: inout GraphicsContext, x: CGFloat, rim: CGFloat, r R: CGFloat, t: Double) {
        let hug = CGFloat(fclamp((t - 2.8) / 1.2, 0, 1))
        let sil = Color(hex: "#1d1418"), H = R * 0.62, feet = rim + R * 0.3
        let wx = x + R * 0.14 - hug * R * 0.06, mx = x - R * 0.15 + hug * R * 0.07
        figure(&ctx, cx: wx, feet: feet, hgt: H, dress: true, color: sil)
        figure(&ctx, cx: mx, feet: feet, hgt: H * (0.66 + 0.34 * hug), dress: false, color: sil)
        let lw = max(1.2, R * 0.05)
        if hug < 0.5 {
            let mh = H * 0.66, hy = feet - mh * 0.55
            var arm = Path()
            arm.move(to: CGPoint(x: mx + mh * 0.08, y: hy))
            arm.addLine(to: CGPoint(x: mx + R * 0.12, y: hy - mh * 0.1))
            ctx.stroke(arm, with: .color(sil), style: StrokeStyle(lineWidth: lw, lineCap: .round))
            let rr = max(1.4, R * 0.035)
            ScenePainter.ell(&ctx, mx + R * 0.13, hy - mh * 0.12, rr, rr, Color(hex: "#ffd27a"))
        } else {
            var arm = Path()
            arm.move(to: CGPoint(x: mx, y: feet - H * 0.62))
            arm.addQuadCurve(to: CGPoint(x: wx, y: feet - H * 0.62), control: CGPoint(x: (mx + wx) / 2, y: feet - H * 0.78))
            ctx.stroke(arm, with: .color(sil), style: StrokeStyle(lineWidth: lw, lineCap: .round))
        }
        ScenePainter.rect(&ctx, x - R * 0.3, rim, R * 0.6, R * 0.32, Color(hex: "#6b4426"))
    }

    static func figure(_ ctx: inout GraphicsContext, cx: CGFloat, feet: CGFloat, hgt: CGFloat, dress: Bool, color: Color) {
        ScenePainter.ell(&ctx, cx, feet - hgt * 0.9, hgt * 0.12, hgt * 0.12, color)
        let top = feet - hgt * 0.76
        let a: CGFloat = dress ? 0.09 : 0.12, b: CGFloat = dress ? 0.2 : 0.11
        var p = Path()
        p.move(to: CGPoint(x: cx - hgt * a, y: top))
        p.addLine(to: CGPoint(x: cx + hgt * a, y: top))
        p.addLine(to: CGPoint(x: cx + hgt * b, y: feet))
        p.addLine(to: CGPoint(x: cx - hgt * b, y: feet))
        p.closeSubpath()
        ctx.fill(p, with: .color(color))
    }

    // MARK: Overlays drawn in the scene

    /// v111.1: the landing field glows as a soft column up the sky, like the thermal, so the goal is easy to spot.
    static func fieldColumn(_ ctx: inout GraphicsContext, cam: SceneCamera, target tx: Double) {
        let X = cam.sx(tx), wv = cam.sx(tx + FlightWorld.landingZone) - X, top = cam.topY, gy = cam.groundY
        for (k, a) in [(1.0 as CGFloat, 0.13), (0.55, 0.16)] {
            let warm = Color(red: 1, green: 200 / 255, blue: 80 / 255)
            ctx.fill(Path(CGRect(x: X - wv * k, y: top, width: wv * 2 * k, height: gy - top)),
                     with: .linearGradient(Gradient(stops: [.init(color: warm.opacity(a), location: 0), .init(color: warm.opacity(a * 0.35), location: 0.75),
                                                             .init(color: warm.opacity(0), location: 1)]),
                                           startPoint: CGPoint(x: X, y: gy), endPoint: CGPoint(x: X, y: top)))
        }
        ctx.draw(Text(verbatim: loc("flight.fieldColumn")).font(sceneFont(13, .heavy, condensed: true)).foregroundColor(.white),
                 at: CGPoint(x: X, y: cam.sy(560)))
    }

    /// v111: the wind where the balloon is, green when it carries you toward the field. v121.2 (TestFlight): a small
    /// dark-glass tag like the wind card, above the envelope, so the ground, the landing field and the chimneys below
    /// stay clear while you come down; a coloured disc holds the arrow.
    static func liveWind(_ ctx: inout GraphicsContext, m: FlightModel, bx: CGFloat, y py: CGFloat) {
        let f = m.sim
        guard f.alt > 3, !f.done else { return }
        let wv = FlightWorld.baseWind(at: f.alt, f.weather), wd: CGFloat = wv < 0 ? -1 : 1
        let good = wv * (f.weather.target - f.x >= 0 ? 1 : -1) > 0.3
        let label = ctx.resolve(Text(verbatim: loc("flight.kmh", num(Int((abs(wv) * 3.6).rounded()))))
            .font(sceneFont(13, .bold, condensed: true)).foregroundColor(.white.opacity(0.95)))
        let tw = label.measure(in: CGSize(width: 200, height: 40)).width, pw = tw + 34, ph: CGFloat = 22, px = bx - pw / 2
        ctx.fill(rrect(px, py - ph / 2, pw, ph, ph / 2), with: .color(Color(red: 30 / 255, green: 24 / 255, blue: 64 / 255).opacity(0.62)))
        let cx = px + 12, cr: CGFloat = 7.5
        ctx.fill(Path(ellipseIn: CGRect(x: cx - cr, y: py - cr, width: cr * 2, height: cr * 2)),
                 with: .color(good ? Color(hex: "#22a45d") : Color(hex: "#ff5e3a")))
        var shaft = Path()
        shaft.move(to: CGPoint(x: cx - wd * 3.8, y: py))
        shaft.addLine(to: CGPoint(x: cx + wd * 1.6, y: py))
        ctx.stroke(shaft, with: .color(.white), style: StrokeStyle(lineWidth: 1.8, lineCap: .round))
        var head = Path()
        head.move(to: CGPoint(x: cx + wd * 4.2, y: py))
        head.addLine(to: CGPoint(x: cx + wd * 0.4, y: py - 3.2))
        head.addLine(to: CGPoint(x: cx + wd * 0.4, y: py + 3.2))
        head.closeSubpath()
        ctx.fill(head, with: .color(.white))
        ctx.draw(label, at: CGPoint(x: cx + cr + 5, y: py + 0.5), anchor: .leading)
    }

    /// "Landing zone 1.2 km" pointer when the field is off-screen. In your first flights it rides at the balloon's
    /// height and nudges toward the field, so the goal can't be missed.
    static func fieldPointer(_ ctx: inout GraphicsContext, cam: SceneCamera, m: FlightModel, top: CGFloat, pr: CGFloat) {
        let W = cam.size.width, tx = m.look.target, dx = tx - m.sim.x, tsx = cam.sx(tx)
        guard tsx > W - 20 || tsx < 20 else { return }
        let d: CGFloat = tsx > W / 2 ? 1 : -1
        let co = m.coached
        let ax = (d > 0 ? W - 18 : 18) + (co ? CGFloat(sin(m.T * 5)) * 3 * d : 0)
        let ay = co ? min(max(cam.sy(m.sim.alt) - pr * 1.4, top + 150), cam.groundY - 44) : cam.groundY - 44
        let km = (abs(dx) / 1000).formatted(.number.precision(.fractionLength(0...1)))
        let label = ctx.resolve(Text(verbatim: loc("flight.toField", km)).font(sceneFont(co ? 17 : 15, co ? .heavy : .bold, condensed: true)).foregroundColor(Theme.ink))
        let tw = label.measure(in: CGSize(width: W, height: 100)).width
        ctx.fill(rrect(d > 0 ? ax - tw - 34 : ax - 6, ay - 15, tw + 40, 30, 15), with: .color(.white))
        var tri = Path()
        tri.move(to: CGPoint(x: ax + d * 8, y: ay))
        tri.addLine(to: CGPoint(x: ax - d * 4, y: ay - 7))
        tri.addLine(to: CGPoint(x: ax - d * 4, y: ay + 7))
        tri.closeSubpath()
        ctx.fill(tri, with: .color(Theme.coral))
        ctx.draw(label, at: CGPoint(x: ax - d * 12, y: ay), anchor: d > 0 ? .trailing : .leading)
    }

    /// Proposal band and panorama line.
    static func missionGuides(_ ctx: inout GraphicsContext, cam: SceneCamera, m: FlightModel) {
        guard let mis = m.look.mission, !m.sim.missionDone else { return }
        let W = cam.size.width
        if mis == .proposal {
            let alt = m.sim.alt, inBand = alt >= 250 && alt <= 350, pulse = 0.5 + 0.5 * sin(m.T * 4)
            let y0 = cam.sy(350), y1 = cam.sy(250)
            ScenePainter.rect(&ctx, 0, y0, W, y1 - y0, Color(red: 1, green: 95 / 255, blue: 150 / 255).opacity(inBand ? 0.26 + 0.1 * pulse : 0.16))
            let pink = Color(red: 1, green: 140 / 255, blue: 180 / 255).opacity(0.95)
            hline(&ctx, y: y0, width: W, color: pink, lineWidth: 2, dash: [8, 6])
            hline(&ctx, y: y1, width: W, color: pink, lineWidth: 2, dash: [8, 6])
            let label = ctx.resolve(Text(verbatim: m.look.zoneText).font(sceneFont(14, .heavy, condensed: true)).foregroundColor(.white))
            let tw = label.measure(in: CGSize(width: W, height: 100)).width
            ctx.draw(label, at: CGPoint(x: W - 12, y: y0 + 13), anchor: .trailing)
            ScenePainter.heart(&ctx, W - 12 - tw - 12, y0 + 13, 6, Color(hex: "#ff6fa8"))
        } else if mis == .panorama {
            hline(&ctx, y: cam.sy(550), width: W, color: Color(red: 1, green: 194 / 255, blue: 61 / 255).opacity(0.9), lineWidth: 2, dash: [8, 6])
        }
    }

    /// Mission pill at the top; pops into "Mission complete! +€X" and fades.
    static func missionBanner(_ ctx: inout GraphicsContext, width W: CGFloat, top: CGFloat, m: FlightModel) {
        guard let mis = m.look.mission else { return }
        var k = 0.0
        var done = false
        if let at = m.mdoneAt {
            if m.T - at > 3.6 { return }
            done = true
            k = fclamp((m.T - at) / 3.6, 0, 1)
        }
        let progress = mis == .proposal && !done
        var text = m.look.missionTitle
        if done {
            text = m.look.rewardPop
        } else if mis == .proposal {
            text += "  " + loc("flight.proposalProgress", m.sim.missionProgress.formatted(.number.precision(.fractionLength(1))))
        }
        let label = ctx.resolve(Text(verbatim: text).font(sceneFont(17, .heavy, condensed: true)).foregroundColor(.white))
        let tw = label.measure(in: CGSize(width: W, height: 100)).width
        let pw = tw + 32, ph: CGFloat = progress ? 40 : 32
        var sc = 1.0
        if done { sc = k < 0.12 ? 1 + k / 0.12 * 0.3 : k < 0.3 ? 1.3 - (k - 0.12) / 0.18 * 0.3 : 1 }
        let fade = done && k > 0.7 ? (k - 0.7) / 0.3 : 0
        var c = ctx
        c.opacity = 1 - fade
        c.translateBy(x: W / 2, y: top + 142 - CGFloat(fade * 24)) // TestFlight: clear of the tip box at the top left
        c.scaleBy(x: CGFloat(sc), y: CGFloat(sc))
        let box = rrect(-pw / 2, -ph / 2, pw, ph, 16)
        c.fill(box, with: .color(done ? Theme.green : Color(red: 43 / 255, green: 35 / 255, blue: 80 / 255).opacity(0.92)))
        if done { c.stroke(box, with: .color(.white.opacity(0.7)), lineWidth: 2) }
        c.draw(label, at: CGPoint(x: 0, y: progress ? -7 : 0), anchor: .center)
        if progress {
            c.fill(rrect(-pw / 2 + 12, 8, pw - 24, 6, 3), with: .color(.white.opacity(0.18)))
            if m.sim.missionProgress > 0.05 {
                let w = (pw - 24) * CGFloat(min(1, m.sim.missionProgress / 8))
                c.fill(rrect(-pw / 2 + 12, 8, w, 6, 3), with: .color(Color(hex: "#ff6fa8")))
            }
        }
    }

    /// Altitude, vertical speed and fuel, top right.
    static func panel(_ ctx: inout GraphicsContext, width W: CGFloat, top: CGFloat, m: FlightModel) {
        let f = m.sim
        let iw: CGFloat = 132, ix = W - iw - 12, iy = top + 4
        ctx.fill(rrect(ix, iy, iw, 92, 16), with: .color(.white.opacity(0.94)))
        let small = sceneFont(11, .semibold), big = sceneFont(22, .heavy, condensed: true)
        ctx.draw(Text(verbatim: m.look.altLabel).font(small).foregroundColor(Theme.ink2), at: CGPoint(x: ix + 12, y: iy + 14), anchor: .leading)
        ctx.draw(Text(verbatim: m.look.vertLabel).font(small).foregroundColor(Theme.ink2), at: CGPoint(x: ix + 72, y: iy + 14), anchor: .leading)
        let altText = loc("flight.meters", num(Int(f.alt.rounded())))
        ctx.draw(Text(verbatim: altText).font(big).foregroundColor(Theme.ink), at: CGPoint(x: ix + 12, y: iy + 32), anchor: .leading)
        let vyText = (f.vy >= 0 ? "↑" : "↓") + abs(f.vy).formatted(.number.precision(.fractionLength(1)))
        let vyColor = abs(f.vy) > 2.6 && f.vy < 0 ? Theme.red : Theme.ink
        ctx.draw(Text(verbatim: vyText).font(big).foregroundColor(vyColor), at: CGPoint(x: ix + 72, y: iy + 32), anchor: .leading)
        ctx.draw(Text(verbatim: m.look.fuelLabel).font(small).foregroundColor(Theme.ink2), at: CGPoint(x: ix + 12, y: iy + 58), anchor: .leading)
        ctx.fill(rrect(ix + 12, iy + 68, iw - 24, 10, 5), with: .color(Color(hex: "#ece7f4")))
        if f.fuel > 1 {
            let w = (iw - 24) * CGFloat(f.fuel / 100)
            ctx.fill(rrect(ix + 12, iy + 68, w, 10, 5), with: .color(f.fuel < 20 ? Theme.red : Theme.coral))
        }
    }
}
