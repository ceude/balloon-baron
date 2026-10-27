import SwiftUI
import BalloonBaronCore

/// One of the balloons floating in the sky on the pick step (`PICK` in the prototype).
struct PickBalloon {
    let colors: [String]
    let x: CGFloat, y: CGFloat, scale: Double

    static let all: [PickBalloon] = [
        PickBalloon(colors: ["#ff5e3a", "#ffc23d"], x: 0.5, y: 0.34, scale: 1.05),
        PickBalloon(colors: ["#14a39a", "#e8fff9"], x: 0.2, y: 0.26, scale: 0.9),
        PickBalloon(colors: ["#2b2350", "#ffc23d"], x: 0.8, y: 0.27, scale: 0.95),
        PickBalloon(colors: ["#ff6fa8", "#fff0f6"], x: 0.3, y: 0.45, scale: 0.75),
        PickBalloon(colors: ["#5aa9e6", "#eaf4fc"], x: 0.7, y: 0.46, scale: 0.62),
        PickBalloon(colors: ["#9b7be0", "#f2ebff"], x: 0.1, y: 0.48, scale: 0.55),
        PickBalloon(colors: ["#22a45d", "#fff3b0"], x: 0.9, y: 0.5, scale: 0.5),
        PickBalloon(colors: ["#e5432f", "#ffffff"], x: 0.4, y: 0.17, scale: 0.6),
        PickBalloon(colors: ["#b5532c", "#fbe6c8"], x: 0.66, y: 0.13, scale: 0.5), // v121.4: was yellow/navy, the navy/yellow one again
        PickBalloon(colors: ["#1f1b2e", "#ffffff"], x: 0.08, y: 0.16, scale: 0.45)
    ]
}

/// Where a pick balloon is this frame; `y` is the bottom of its basket.
struct PickSpot {
    let i: Int
    let x: CGFloat, y: CGFloat, r: CGFloat
}

/// Animated scales of the pick balloons (the selected one grows to 1.5×).
final class PickModel {
    var scales = PickBalloon.all.map(\.scale)
    var size = CGSize.zero
    var T = 0.0

    func update(selected: Int, dt: Double) {
        let k = min(1, dt * 8)
        for i in scales.indices {
            let target = i == selected ? 1.5 : PickBalloon.all[i].scale
            scales[i] += (target - scales[i]) * k
        }
    }

    /// `pickSpots()`: bobbing positions, smallest first so the big ones draw on top.
    func spots() -> [PickSpot] {
        let W = size.width, H = size.height
        let base = min(W * 0.1, H * 0.065)
        return PickBalloon.all.indices.map { (i: Int) -> PickSpot in
            let p = PickBalloon.all[i], fi = Double(i)
            return PickSpot(i: i, x: W * p.x + CGFloat(sin(T * 0.3 + fi)) * 8, y: H * p.y + CGFloat(sin(T * 1.1 + fi * 1.7)) * 6,
                            r: base * CGFloat(scales[i]))
        }
        .sorted { $0.r < $1.r }
    }

    /// The balloon under a tap, biggest first.
    func hit(_ pt: CGPoint) -> Int? {
        spots().reversed().first { b in hypot(pt.x - b.x, pt.y - (b.y - b.r * 2)) < b.r * 1.5 }?.i
    }
}

/// New company: name it, then pick your balloon from the ones floating in the dawn sky. Inside the opening film
/// (`opening`) the cards float over the 3D scene instead, which shows the pick in its own sky and plays the lift-off.
struct SetupView: View {
    @Environment(GameStore.self) private var store
    @State private var step = 1
    @State private var name = ""
    @State private var error = false
    @State private var localPick = 0
    @State private var scene = DawnSceneModel()
    @State private var picker = PickModel()
    @FocusState private var focused: Bool
    private let opening: OpeningFlow?

    init(opening: OpeningFlow? = nil) {
        self.opening = opening
    }

    private static let maxName = 24
    private var trimmed: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }

    /// The chosen balloon: the film's when it shows the pick.
    private var pick: Int {
        get { opening?.pick ?? localPick }
        nonmutating set {
            if let opening { opening.choose(newValue) } else { localPick = newValue }
        }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            if opening == nil { sky } else { Color.clear.allowsHitTesting(false) }
            card
                .padding(16)
                .frame(maxWidth: .infinity)
        }
        .animation(.easeOut(duration: 0.25), value: step)
        .onAppear { SoundEngine.shared.start() }
        .onChange(of: step) { _, s in opening?.setPicking(s == 2) }
    }

    // MARK: Scene

    private var sky: some View {
        let picking = step == 2
        let selected = pick
        return TimelineView(.animation) { tl in
            Canvas { ctx, size in
                drawFrame(&ctx, size: size, date: tl.date, picking: picking, selected: selected)
            }
            .onTapGesture { pt in
                guard step == 2, let i = picker.hit(pt) else { return }
                pick = i
            }
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }

    private func drawFrame(_ ctx: inout GraphicsContext, size: CGSize, date: Date, picking: Bool, selected: Int) {
        scene.prepare(nil)
        let T = scene.time(date)
        let dt = scene.step(T)
        let cam = DawnSceneModel.camera(size)
        scene.backdrop(&ctx, cam: cam, p: 0.3, showBackground: !picking, T: T, dt: dt)
        guard picking else { return }
        picker.size = size
        picker.T = T
        picker.update(selected: selected, dt: dt)
        for b in picker.spots() {
            let sel = b.i == selected
            if sel { glow(&ctx, b) }
            // In full volume (v110), like the balloon you fly; the envelope keeps the flat one's size.
            ScenePainter.balloon3d(&ctx, x: b.x, y: b.y, r: b.r / 0.86, colors: PickBalloon.all[b.i].colors,
                                   burn: sel && sin(T * 6) > 0, alpha: sel ? 1 : 0.85, region: scene.region)
        }
    }

    private func glow(_ ctx: inout GraphicsContext, _ b: PickSpot) {
        let c = Color(red: 1, green: 240 / 255, blue: 200 / 255)
        let center = CGPoint(x: b.x, y: b.y - b.r * 1.5)
        ctx.fill(Path(CGRect(x: b.x - b.r * 3, y: b.y - b.r * 4.2, width: b.r * 6, height: b.r * 5.5)),
                 with: .radialGradient(Gradient(colors: [c.opacity(0.75), c.opacity(0)]), center: center,
                                       startRadius: 0, endRadius: b.r * 2.6))
    }

    // MARK: Card

    private var card: some View {
        Group {
            if step == 1 { nameStep } else { pickStep }
        }
        .padding(.vertical, 22)
        .padding(.horizontal, 20)
        .frame(maxWidth: 420, alignment: .leading)
        .background(Theme.paper, in: RoundedRectangle(cornerRadius: 24))
        .compositingGroup()
        .shadow(color: Color(red: 20 / 255, green: 10 / 255, blue: 40 / 255).opacity(0.4), radius: 20, y: 10)
        .transition(.opacity)
    }

    private func title(_ key: String) -> some View {
        Text(loc(key))
            .font(Theme.font(32, .heavy, condensed: true))
            .foregroundStyle(Theme.ink)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func lead(_ text: String) -> some View {
        Text(text)
            .font(Theme.font(16))
            .foregroundStyle(Theme.ink2)
            .lineSpacing(3)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var nameStep: some View {
        VStack(alignment: .leading, spacing: 14) {
            title("intro.setup.title")
            lead(loc("intro.setup.lead"))
            nameField
            suggestions
            if error {
                Text(loc("intro.setup.error"))
                    .font(Theme.font(13.5))
                    .foregroundStyle(Theme.red)
                    .fixedSize(horizontal: false, vertical: true)
            }
            BigButton(title: loc("intro.setup.continue"), action: next)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.06) { focused = true }
        }
    }

    private var nameField: some View {
        TextField(loc("intro.setup.placeholder"), text: $name)
            .font(Theme.font(18, .semibold))
            .foregroundStyle(Theme.ink)
            .autocorrectionDisabled()
            .textInputAutocapitalization(.words)
            .submitLabel(.next)
            .focused($focused)
            .onSubmit(next)
            .padding(.horizontal, 14)
            .frame(height: 50)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(focused ? Theme.sun : Theme.line, lineWidth: focused ? 3 : 2))
            .onChange(of: name) { _, v in
                if v.count > Self.maxName { name = String(v.prefix(Self.maxName)) }
                if error && !trimmed.isEmpty { error = false }
            }
    }

    private var suggestions: some View {
        HoldingChipFlow(spacing: 6) {
            ForEach(1...5, id: \.self) { i in
                let n = loc("intro.setup.sugg\(i)")
                Button {
                    SoundEngine.shared.play(.click)
                    name = n
                } label: {
                    Text(n)
                        .font(Theme.font(13.5, .semibold))
                        .foregroundStyle(Theme.ink)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color(hex: "#f1edf8"), in: RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var pickStep: some View {
        VStack(alignment: .leading, spacing: 14) {
            title("intro.pick.title")
            lead(loc("intro.pick.lead", trimmed))
            pickA11y
            HStack(spacing: 10) {
                BigButton(title: loc("intro.pick.back"), style: .ghost) {
                    SoundEngine.shared.play(.click)
                    step = 1
                }
                BigButton(title: loc("intro.pick.fly")) {
                    SoundEngine.shared.play(.click)
                    let colors = PickBalloon.all[pick].colors
                    if let opening {
                        // The game is made now (and saved); the lift-off plays over it before the town comes up.
                        store.openingFilm = true
                        store.newGame(company: trimmed, colors: colors)
                        opening.liftOff(company: trimmed, colors: colors, state: store.state)
                    } else {
                        store.newGame(company: trimmed, colors: colors)
                    }
                }
            }
        }
    }

    /// VoiceOver can't tap the canvas: an adjustable element cycles the sky balloons.
    private var pickA11y: some View {
        let n = PickBalloon.all.count
        return Color.clear
            .frame(height: 1)
            .accessibilityElement()
            .accessibilityLabel(loc("setup.color"))
            .accessibilityValue(loc("intro.pick.balloon", num(pick + 1), num(n)))
            .accessibilityAdjustableAction { dir in
                switch dir {
                case .increment: pick = (pick + 1) % n
                case .decrement: pick = (pick + n - 1) % n
                @unknown default: break
                }
            }
    }

    private func next() {
        SoundEngine.shared.play(.click)
        guard !trimmed.isEmpty else {
            error = true
            focused = true
            return
        }
        focused = false
        step = 2
    }
}

/// Simple code-drawn balloon used in menus until the SpriteKit art lands.
struct BalloonShape: View {
    let colors: [String]

    var body: some View {
        GeometryReader { g in
            let w = g.size.width, h = g.size.height
            ZStack {
                Ellipse()
                    .fill(Color(hex: colors[0]))
                    .frame(width: w, height: h * 0.78)
                    .position(x: w / 2, y: h * 0.39)
                Ellipse()
                    .fill(Color(hex: colors[1]))
                    .frame(width: w * 0.32, height: h * 0.78)
                    .position(x: w / 2, y: h * 0.39)
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color(hex: "#6b4426"))
                    .frame(width: w * 0.22, height: h * 0.13)
                    .position(x: w / 2, y: h * 0.92)
            }
        }
    }
}
