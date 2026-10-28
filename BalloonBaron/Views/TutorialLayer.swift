import SwiftUI
import BalloonBaronCore

// v122: the tutorial that shows (prototype `#tut`, `tutFrame`). The screen dims with holes cut out for what to use,
// a dashed gold ring around them, a bouncing arrow, and one line with Hezarfen's small face and "Skip". The layer
// never takes a tap (only its line does), so the game below keeps working and nothing can lock it.

/// Views the tutorial can point at report their frame under an id (`.tutSpot`). Each presentation (the root screen,
/// the price sheet, the flight) collects its own spots and draws its own layer.
struct TutSpotKey: PreferenceKey {
    static var defaultValue: [String: Anchor<CGRect>] = [:]
    static func reduce(value: inout [String: Anchor<CGRect>], nextValue: () -> [String: Anchor<CGRect>]) {
        value.merge(nextValue()) { a, _ in a }
    }
}

/// Which spots are on screen, and whether each one's button is disabled (a guided action then says why).
struct TutPresentKey: PreferenceKey {
    static var defaultValue: [String: Bool] = [:]
    static func reduce(value: inout [String: Bool], nextValue: () -> [String: Bool]) {
        value.merge(nextValue()) { a, _ in a }
    }
}

extension View {
    /// Marks a view the tutorial may light up. `disabled`: the button can't be used yet (not enough cash).
    func tutSpot(_ id: String, disabled: Bool = false) -> some View {
        self
            .anchorPreference(key: TutSpotKey.self, value: .bounds) { [id: $0] }
            .transformPreference(TutPresentKey.self) { $0[id] = disabled }
    }
}

/// A hole in the dim: a rounded rectangle, or a circle for round buttons and the balloon.
struct TutHole: Equatable {
    var rect: CGRect
    var radius: CGFloat = 16
    static func circle(_ c: CGPoint, _ r: CGFloat) -> TutHole {
        TutHole(rect: CGRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2), radius: r)
    }
    func padded(_ p: CGFloat, round: Bool = false) -> TutHole {
        let r = rect.insetBy(dx: -p, dy: -p)
        return TutHole(rect: r, radius: round ? r.height / 2 : radius)
    }
}

/// Where the arrow points from, and which way. `up` points up (it sits under the thing it shows).
struct TutArrow {
    enum Dir { case up, down, left, right }
    var at: CGPoint
    var dir: Dir

    /// `tutArrowAt`: above the hole pointing down, or under it pointing up when the hole is near the top.
    static func toward(_ h: TutHole) -> TutArrow {
        let q = h.rect
        return q.minY > 150 ? TutArrow(at: CGPoint(x: q.midX, y: q.minY - 26), dir: .down)
            : TutArrow(at: CGPoint(x: q.midX, y: q.maxY + 26), dir: .up)
    }
}

/// What a layer shows this frame. Rects are in global (screen) coordinates.
struct TutFrame {
    var key: String
    var holes: [TutHole]
    /// nil: the default arrow at the first hole; `.none` hides it.
    var arrow: TutArrow?? = nil
    var line: String
    /// The long lesson behind "More" (guided actions).
    var more: String?
    /// In flight the dark lifts after a moment so the chimneys stay visible; ring, arrow and line stay.
    var dim: Double = 0.62
    /// Where the line goes (its top), or nil: clear of every hole.
    var lineY: CGFloat?
}

/// Resolves a host's spots into global rectangles.
struct TutSpots {
    let rects: [String: CGRect]
    init(_ anchors: [String: Anchor<CGRect>], _ proxy: GeometryProxy) {
        let o = proxy.frame(in: .global).origin
        rects = anchors.mapValues { proxy[$0].offsetBy(dx: o.x, dy: o.y) }
    }
    func hole(_ id: String, pad: CGFloat = 6, round: Bool = false) -> TutHole? {
        rects[id].map { TutHole(rect: $0).padded(pad, round: round) }
    }
}

/// The dim, the holes, the ring, the arrow and the line, drawn over a whole presentation. Its frame comes from
/// `frame()` on every animation tick (holes that move with the scene, a building the town glides to).
struct TutorialLayer: View {
    /// The safe top under which the line stays (under the top bar).
    var minLineY: CGFloat = 60
    /// Something may come up: the layer animates; otherwise it sleeps.
    let alive: () -> Bool
    let frame: () -> TutFrame?
    let onSkip: () -> Void
    @State private var t0 = Date()
    @State private var shownKey = ""
    @State private var expanded = false
    @State private var lineH: CGFloat = 46

    var body: some View {
        let live = alive()
        GeometryReader { geo in
            let origin = geo.frame(in: .global).origin
            TimelineView(.animation(minimumInterval: nil, paused: !live)) { tl in
                if let f = visible(frame(), size: geo.size, origin: origin) {
                    let t = tl.date.timeIntervalSince(t0)
                    ZStack(alignment: .topLeading) {
                        Canvas { ctx, size in draw(&ctx, f, t: t) }
                            .allowsHitTesting(false)
                        lineView(f)
                            .background(GeometryReader { g in Color.clear.preference(key: TutLineHeight.self, value: g.size.height) })
                            .frame(maxWidth: .infinity)
                            .offset(y: lineTop(f, height: geo.size.height))
                    }
                    .onAppear { restart(f.key) }
                    .onChange(of: f.key) { _, k in restart(k) }
                }
            }
        }
        .ignoresSafeArea()
        .onPreferenceChange(TutLineHeight.self) { h in if h > 0 && abs(h - lineH) > 0.5 { lineH = h } }
    }

    private func restart(_ k: String) {
        guard k != shownKey else { return }
        shownKey = k
        expanded = false
        t0 = Date()
    }

    /// The frame moved into this layer's coordinates, keeping the holes that are on screen; nil hides the layer.
    private func visible(_ f: TutFrame?, size: CGSize, origin: CGPoint) -> TutFrame? {
        guard var f else { return nil }
        let screen = CGRect(origin: .zero, size: size)
        f.holes = f.holes.map { h in var h = h; h.rect = h.rect.offsetBy(dx: -origin.x, dy: -origin.y); return h }
            .filter { $0.rect.width > 1 && $0.rect.intersects(screen) && $0.rect.maxY > 0 && $0.rect.minY < size.height }
        if case .some(.some(let a)) = f.arrow {
            f.arrow = .some(TutArrow(at: CGPoint(x: a.at.x - origin.x, y: a.at.y - origin.y), dir: a.dir))
        }
        if let y = f.lineY { f.lineY = y - origin.y }
        return f.holes.isEmpty ? nil : f
    }

    private func lineTop(_ f: TutFrame, height H: CGFloat) -> CGFloat {
        let top = f.holes.map(\.rect.minY).min() ?? 0, bot = f.holes.map(\.rect.maxY).max() ?? 0
        let y = f.lineY ?? ((top + bot) / 2 > H * 0.5 ? top - 64 - lineH : bot + 64)
        return min(max(y, minLineY), max(minLineY, H - lineH - 10))
    }

    private func draw(_ ctx: inout GraphicsContext, _ f: TutFrame, t: Double) {
        let full = CGRect(origin: .zero, size: ctx.clipBoundingRect.size)
        var holes = Path()
        for h in f.holes { holes.addRoundedRect(in: h.rect, cornerSize: CGSize(width: min(h.radius, h.rect.width / 2, h.rect.height / 2), height: min(h.radius, h.rect.width / 2, h.rect.height / 2))) }
        var dim = Path(full.insetBy(dx: -40, dy: -40))
        dim.addPath(holes)
        ctx.fill(dim, with: .color(Color(red: 16 / 255, green: 10 / 255, blue: 36 / 255).opacity(f.dim)), style: FillStyle(eoFill: true))
        ctx.stroke(holes, with: .color(Color(hex: "#ffd27a")),
                   style: StrokeStyle(lineWidth: 3, dash: [7, 6], dashPhase: CGFloat(-t * 26)))
        let arrow: TutArrow? = {
            switch f.arrow {
            case .none: return f.holes.first.map { TutArrow.toward($0) }
            case .some(let a): return a
            }
        }()
        if let a = arrow { drawArrow(&ctx, a, t: t) }
    }

    /// The prototype's arrow: a white outline around a coral stroke, bobbing 9 pt every 0.8 s.
    private func drawArrow(_ ctx: inout GraphicsContext, _ a: TutArrow, t: Double) {
        var c = ctx
        let bob = -9 * (0.5 - 0.5 * cos(t / 0.8 * 2 * .pi))
        c.translateBy(x: a.at.x, y: a.at.y)
        let deg: Double
        switch a.dir {
        case .up: deg = 0
        case .right: deg = 90
        case .down: deg = 180
        case .left: deg = -90
        }
        c.rotate(by: .degrees(deg))
        c.translateBy(x: 0, y: bob)
        var p = Path()
        p.move(to: CGPoint(x: 0, y: 18)); p.addLine(to: CGPoint(x: 0, y: -10))
        p.move(to: CGPoint(x: -12, y: 0)); p.addLine(to: CGPoint(x: 0, y: -14)); p.addLine(to: CGPoint(x: 12, y: 0))
        var sh = c
        sh.addFilter(.shadow(color: .black.opacity(0.45), radius: 3, y: 3))
        sh.stroke(p, with: .color(.white), style: StrokeStyle(lineWidth: 10, lineCap: .round, lineJoin: .round))
        c.stroke(p, with: .color(Color(hex: "#ff5e3a")), style: StrokeStyle(lineWidth: 5.5, lineCap: .round, lineJoin: .round))
    }

    @ViewBuilder
    private func lineView(_ f: TutFrame) -> some View {
        let long = expanded ? f.more : nil
        let content = HStack(spacing: 8) {
            GuideAvatar(region: currentRegion, size: 34)
            Text(long ?? f.line)
                .font(long != nil ? Theme.font(14.5, .medium) : Theme.font(17, .bold, condensed: true))
                .foregroundStyle(Theme.ink)
                .lineSpacing(long != nil ? 2 : 0)
                .fixedSize(horizontal: false, vertical: true)
                .layoutPriority(1)
            if f.more != nil && !expanded {
                Button {
                    SoundEngine.shared.play(.click)
                    expanded = true
                } label: {
                    Text(loc("tut.more")).font(Theme.font(13, .bold)).underline().foregroundStyle(Theme.ink2)
                        .lineLimit(1).fixedSize()
                        .padding(.horizontal, 6).frame(height: 30)
                }
                .buttonStyle(.plain)
            }
            Button {
                SoundEngine.shared.play(.click)
                onSkip()
            } label: {
                Text(loc("tut.skip")).font(Theme.font(13, .bold)).foregroundStyle(Color(hex: "#6c6488"))
                    .lineLimit(1).fixedSize()
                    .padding(.horizontal, 11).frame(height: 30)
                    .background(Color(hex: "#ece7f4"), in: Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(6)
        .background(Color.white, in: RoundedRectangle(cornerRadius: long != nil ? 18 : 30, style: .continuous))
        .compositingGroup()
        .shadow(color: Color(red: 15 / 255, green: 8 / 255, blue: 35 / 255).opacity(0.45), radius: 12, y: 8)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(loc("tut.a11y"))
        content
            .frame(maxWidth: long != nil ? 420 : nil)
            .padding(.horizontal, 16)
            .id(f.key)
            .transition(.opacity.combined(with: .offset(y: 8)))
    }
}

private struct TutLineHeight: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = max(value, nextValue()) }
}

extension View {
    /// A presentation that hosts the tutorial: its spots are collected here and the layer is drawn over it.
    /// `frame` turns the spots on screen into what to show (nil: nothing).
    func tutorialHost(minLineY: CGFloat = 60, present: (([String: Bool]) -> Void)? = nil, alive: @escaping () -> Bool,
                      frame: @escaping (TutSpots) -> TutFrame?, onSkip: @escaping () -> Void) -> some View {
        self
            .onPreferenceChange(TutPresentKey.self) { present?($0) }
            .overlayPreferenceValue(TutSpotKey.self) { anchors in
                GeometryReader { proxy in
                    let spots = TutSpots(anchors, proxy)
                    TutorialLayer(minLineY: minLineY, alive: alive, frame: { frame(spots) }, onSkip: onSkip)
                }
            }
    }
}
