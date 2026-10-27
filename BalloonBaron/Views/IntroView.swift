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
        if hold { vy = min(vy + 240 * dt, 230); Haptics.burner(at: t) } else { vy = max(vy - 160 * dt, y > 0 ? -35 : 0) }
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
    @State private var pressed = false
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
                    VStack(spacing: 18) {
                        // The very first time: where to press, until the balloon starts to rise.
                        if s == nil && !pressed { hint }
                        burnButton
                    }
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
            // A new company: the opening film's set builds in the background while the balloon rises.
            if store.state == nil && !reduceMotion { OpeningLoader.shared.preload() }
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
            Circle()
                .fill(RadialGradient(colors: [Color(hex: "#ff8a5a"), .clear], center: UnitPoint(x: 0.5, y: 0.35), startRadius: 0, endRadius: 40))
                .frame(width: 104, height: 104)
            VStack(spacing: 0) {
                FlameIcon()
                    .frame(width: 34, height: 34)
                    .shadow(color: Color(hex: "#ffc85a").opacity(0.8), radius: 6)
                Text(loc("intro.burn"))
                    .font(Theme.font(19, .heavy, condensed: true))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .frame(width: 92)
            }
            .offset(y: -3)
        }
        .offset(y: holding ? 5 : 0)
        .animation(.easeOut(duration: 0.08), value: holding)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(loc("intro.burn.a11y"))
        .accessibilityAddTraits(.isButton)
        // VoiceOver can't press and hold: activating keeps the burner on until the balloon is away.
        .accessibilityAction { setHold(true) }
    }

    /// "Hold the burner" in a white speech bubble whose notch points at the button, bobbing gently (`#introHint`).
    private var hint: some View {
        TimelineView(.animation) { tl in
            // CSS `hint` keyframes: 1.6 s ease-in-out, down 4 pt and back.
            let k = reduceMotion ? 0 : (1 - cos(tl.date.timeIntervalSinceReferenceDate * 2 * Double.pi / 1.6)) / 2
            Text(loc("intro.hint"))
                .font(Theme.font(18, .heavy, condensed: true))
                .tracking(0.36)
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
                .padding(.vertical, 10)
                .padding(.horizontal, 18)
                .background(alignment: .bottom) {
                    ZStack(alignment: .bottom) {
                        RoundedRectangle(cornerRadius: 16).fill(Color.white)
                        // the notch: a square turned 45°, half below the bubble, its rounded corner at the tip
                        UnevenRoundedRectangle(bottomTrailingRadius: 3)
                            .fill(Color.white)
                            .frame(width: 14, height: 14)
                            .rotationEffect(.degrees(45))
                            .offset(y: 7)
                    }
                    .compositingGroup()
                    .shadow(color: Color(red: 20 / 255, green: 10 / 255, blue: 40 / 255).opacity(0.35), radius: 12, y: 8)
                }
                .offset(y: CGFloat(4 * k))
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 4)
        .accessibilityHidden(true)
        .transition(.opacity)
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
        if on { withAnimation(.easeOut(duration: 0.3)) { pressed = true } }
        SoundEngine.shared.burner(on)
        Haptics.burnerToggled(on: on)
    }

    // MARK: Drawing

    private func drawFrame(_ ctx: inout GraphicsContext, size: CGSize, state: GameState?, date: Date) {
        scene.prepare(state)
        let T = scene.time(date)
        let dt = scene.step(T)
        intro.step(dt)
        let gy = size.height * 0.74
        // Rising, the balloon comes towards you: it grows, and passing the title it throws a soft shadow on it.
        let R0 = min(size.width, size.height) * 0.1
        let near = min(1, intro.y / Double(size.height * 0.55))
        let R = R0 * CGFloat(1 + 0.85 * pow(near, 1.6))
        let y = CGFloat(intro.y)
        if !intro.out && gy - y - R0 * 2.7 < -8 {
            intro.out = true
            DispatchQueue.main.async { leave() }
        }
        IntroScene.draw(&ctx, size: size, region: scene.region.rawValue, gy: gy, t: T, lift: min(1, intro.y / Double(size.height * 0.45)))
        let sway: CGFloat = intro.y > 2 ? CGFloat(sin(intro.t * 2.1)) * R * 0.1 : 0
        let bx = size.width / 2 + sway, by = gy + R0 * 0.1 - y
        ScenePainter.ell(&ctx, size.width / 2, gy + R0 * 0.12, R0 * 0.6 / (1 + y / 120), R0 * 0.12,
                         Color(red: 40 / 255, green: 20 / 255, blue: 30 / 255).opacity(0.3))
        if near > 0.2 {
            var shadow = ctx
            shadow.addFilter(.blur(radius: R * 0.35))
            ScenePainter.ell(&shadow, bx + R * 0.5, by - R * 1.3, R * 0.95, R * 1.15,
                             Color(red: 20 / 255, green: 8 / 255, blue: 30 / 255).opacity(0.38 * min(1, (near - 0.2) * 2)))
        }
        if intro.hold {
            // The burner lights the envelope and the grass.
            var glow = ctx
            glow.blendMode = .plusLighter
            glow.fill(Path(ellipseIn: CGRect(x: bx - R * 2.4, y: by - R * 3.6, width: R * 4.8, height: R * 4.8)), with: .radialGradient(
                Gradient(colors: [Color(red: 1, green: 170 / 255, blue: 70 / 255).opacity(0.35), .clear]),
                center: CGPoint(x: bx, y: by - R * 1.2), startRadius: 0, endRadius: R * 2.4))
        }
        ScenePainter.balloon3d(&ctx, x: bx, y: by, r: R, colors: scene.colors, burn: intro.hold, region: scene.region)
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

/// The burner's flame, for the intro button.
struct FlameIcon: View {
    var body: some View {
        Canvas { ctx, size in
            let k = size.width / 24
            func P(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x * k, y: y * k) }
            var outer = Path()
            outer.move(to: P(12, 2))
            outer.addCurve(to: P(17, 12.2), control1: P(13, 5.5), control2: P(17, 7.6))
            outer.addArc(center: P(12, 12.2), radius: 5 * k, startAngle: .degrees(0), endAngle: .degrees(180), clockwise: false)
            outer.addCurve(to: P(9, 7.8), control1: P(7, 10.2), control2: P(8, 8.8))
            outer.addCurve(to: P(11.2, 11), control1: P(9.2, 9.4), control2: P(10, 10.5))
            outer.addCurve(to: P(12, 2), control1: P(10.6, 8), control2: P(11, 4.6))
            ctx.fill(outer, with: .color(Color(hex: "#ffe08a")))
            var inner = Path()
            inner.move(to: P(12, 11))
            inner.addCurve(to: P(14.6, 15.6), control1: P(12.8, 12.7), control2: P(14.6, 13.6))
            inner.addArc(center: P(12, 15.6), radius: 2.6 * k, startAngle: .degrees(0), endAngle: .degrees(180), clockwise: false)
            inner.addCurve(to: P(12, 11), control1: P(9.4, 14.1), control2: P(11.6, 12.2))
            ctx.fill(inner, with: .color(Color(hex: "#fff6d8")))
        }
    }
}
