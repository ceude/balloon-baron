import SwiftUI
import BalloonBaronCore

/// Shared state of the dawn screens (intro, company setup, balloon pick). Not observed: the canvas
/// mutates it every frame.
final class DawnSceneModel {
    let t0 = Date.timeIntervalSinceReferenceDate
    var last: Double?
    var bg: [BackgroundBalloon] = []
    var weather: Weather?
    var region = RegionID.cap
    var winter = false
    var colors = Rules.palettes[0]
    private var ready = false

    /// Builds the world once: today's weather and background balloons, or a fresh company's
    /// (its starting rivals) when there's no game yet.
    func prepare(_ state: GameState?) {
        guard !ready else { return }
        ready = true
        var s: GameState
        if let state {
            s = state
        } else {
            var g = Game(company: "", colors: Rules.palettes[0])
            g.startDay()
            s = g.state
        }
        weather = s.weather
        region = s.region
        winter = s.local.winter != nil
        colors = s.colors.count >= 2 ? s.colors : Rules.palettes[0]
        bg = ScenePainter.backgroundBalloons(s)
    }

    func time(_ date: Date) -> Double { date.timeIntervalSinceReferenceDate - t0 }

    /// Seconds since the last frame, capped so a paused app doesn't jump.
    func step(_ t: Double) -> Double {
        let dt = last.map { min(0.1, max(0, t - $0)) } ?? 0
        last = t
        return dt
    }

    /// `drawIntro()`'s camera: ground at 74% of the height, launch field centered.
    static func camera(_ size: CGSize) -> SceneCamera {
        SceneCamera(size: size, groundY: size.height * 0.74, topY: 40, focusX: FlightWorld.launchX, focusAt: 0.5)
    }

    /// Sky, ridges and chimneys; drifting background balloons only when `showBackground`.
    func backdrop(_ ctx: inout GraphicsContext, cam: SceneCamera, p: Double, showBackground: Bool, T: Double, dt: Double) {
        if showBackground, let w = weather {
            ScenePainter.drift(&bg, weather: w, cam: cam, dt: dt, time: T, inFlight: false)
        }
        ScenePainter.scenery(&ctx, cam: cam, p: p, region: region, winter: winter, time: T,
                             background: showBackground ? bg : [], inFlight: false)
    }
}

/// The intro balloon's climb (`INTRO` in the prototype).
final class IntroModel {
    var y = 0.0, vy = 0.0, t = 0.0
    var hold = false, out = false

    func step(_ dt: Double) {
        t += dt
        if hold { vy = min(vy + 240 * dt, 230) } else { vy = max(vy - 160 * dt, y > 0 ? -35 : 0) }
        y = max(0, y + vy * dt)
    }
}

/// The dream flight shown at every launch: hold the burner (or anywhere) to lift your balloon off
/// the dawn field; once it leaves the screen, fade to the setup or the office.
struct IntroView: View {
    @Environment(GameStore.self) private var store
    @State private var scene = DawnSceneModel()
    @State private var intro = IntroModel()
    @State private var holding = false
    @State private var out = false
    @State private var fade = false
    /// Reduce Motion: the ring around the burner stays still instead of pulsing.
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let s = store.state
        GeometryReader { g in
            ZStack(alignment: .bottom) {
                TimelineView(.animation) { tl in
                    Canvas { ctx, size in
                        drawFrame(&ctx, size: size, state: s, date: tl.date)
                    }
                }
                .ignoresSafeArea()
                .accessibilityHidden(true)
                if !out {
                    burnButton
                        .padding(.bottom, max(28, g.safeAreaInsets.bottom + 16) - g.safeAreaInsets.bottom)
                }
                Color(hex: "#fff6ea")
                    .opacity(fade ? 1 : 0)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }
            .frame(width: g.size.width, height: g.size.height)
            .contentShape(Rectangle())
            .gesture(holdGesture)
        }
        .onAppear {
            SoundEngine.shared.start()
        }
        .onDisappear { SoundEngine.shared.burner(false) }
    }

    private var holdGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { _ in setHold(true) }
            .onEnded { _ in setHold(false) }
    }

    // MARK: Burner button

    private var burnButton: some View {
        let coralD = Color(hex: "#d9411f")
        return ZStack {
            if !holding { pulseRing }
            Circle()
                .stroke(Theme.sun.opacity(0.45), lineWidth: 10)
                .frame(width: 114, height: 114)
                .opacity(holding ? 1 : 0)
            Circle()
                .fill(coralD)
                .frame(width: 104, height: 104)
                .offset(y: holding ? 2 : 7)
                .shadow(color: Color(red: 40 / 255, green: 10 / 255, blue: 30 / 255).opacity(holding ? 0 : 0.35), radius: 14, y: 12)
            Circle()
                .fill(Theme.coral)
                .frame(width: 104, height: 104)
            Text(loc("intro.burn"))
                .font(Theme.font(19, .heavy, condensed: true))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .frame(width: 92)
        }
        .offset(y: holding ? 5 : 0)
        .animation(.easeOut(duration: 0.08), value: holding)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(loc("intro.burn.a11y"))
        .accessibilityAddTraits(.isButton)
        // VoiceOver can't press and hold: activating keeps the burner on until the balloon is away.
        .accessibilityAction { setHold(true) }
    }

    /// CSS `ring` keyframes: 1.5 s ease-in-out, scale 0.94 to 1.1, opacity 0.9 to 0.35.
    private var pulseRing: some View {
        TimelineView(.animation) { tl in
            let k = reduceMotion ? 0 : (1 - cos(tl.date.timeIntervalSinceReferenceDate * 2 * Double.pi / 1.5)) / 2
            Circle()
                .stroke(Color.white.opacity(0.85), lineWidth: 3)
                .frame(width: 124, height: 124)
                .scaleEffect(CGFloat(0.94 + 0.16 * k))
                .opacity(0.9 - 0.55 * k)
        }
    }

    private func setHold(_ on: Bool) {
        if on { SoundEngine.shared.start() }
        guard !out, holding != on else { return }
        holding = on
        intro.hold = on
        SoundEngine.shared.burner(on)
    }

    // MARK: Drawing

    private func drawFrame(_ ctx: inout GraphicsContext, size: CGSize, state: GameState?, date: Date) {
        scene.prepare(state)
        let T = scene.time(date)
        let dt = scene.step(T)
        intro.step(dt)
        let cam = DawnSceneModel.camera(size)
        let gy = cam.groundY
        let R = min(size.width, size.height) * 0.085
        let y = CGFloat(intro.y)
        if !intro.out && gy - y - R * 2.7 < -8 {
            intro.out = true
            DispatchQueue.main.async { leave() }
        }
        scene.backdrop(&ctx, cam: cam, p: 0.2 + min(0.1, intro.y / 3000), showBackground: false, T: T, dt: dt)
        let sway: CGFloat = intro.y > 2 ? CGFloat(sin(intro.t * 2.1)) * R * 0.1 : 0
        ScenePainter.ell(&ctx, size.width / 2, gy + 3, R * 0.5 / (1 + y / 120), R * 0.1,
                         Color(red: 40 / 255, green: 20 / 255, blue: 30 / 255).opacity(0.25))
        ScenePainter.balloon(&ctx, x: size.width / 2 + sway, y: gy - y, r: R, colors: scene.colors,
                             burn: intro.hold, region: scene.region, time: T)
    }

    /// The balloon is gone: fade to cream, then hand over (setup or office). RootView fades this
    /// view out, revealing the next screen like the prototype's `#fade`.
    private func leave() {
        guard !out else { return }
        out = true
        holding = false
        SoundEngine.shared.burner(false)
        withAnimation(.easeInOut(duration: 0.45)) { fade = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.48) {
            withAnimation(.easeOut(duration: 0.45)) { store.finishIntro() }
        }
    }
}
