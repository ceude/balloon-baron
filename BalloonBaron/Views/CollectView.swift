import SwiftUI
import BalloonBaronCore

/// The prototype's `.big` / `.ghost` buttons: chunky, with a solid drop shadow that sinks when pressed.
struct ChunkyButtonStyle: ButtonStyle {
    enum Kind { case big, ghost, glassGhost }
    var kind: Kind = .big
    var height: CGFloat = 54
    /// Fill the width whatever the kind (big buttons always do).
    var wide = false

    func makeBody(configuration: Configuration) -> some View {
        ChunkyBody(configuration: configuration, kind: kind, height: height, wide: wide)
    }

    private struct ChunkyBody: View {
        let configuration: ButtonStyleConfiguration
        let kind: Kind
        let height: CGFloat
        let wide: Bool
        @Environment(\.isEnabled) private var enabled

        var body: some View {
            let pressed = configuration.isPressed && enabled
            let drop: CGFloat = pressed ? 1 : 5
            return configuration.label
                .font(kind == .big ? Theme.font(22, .heavy, condensed: true) : Theme.font(18, .bold, condensed: true))
                .foregroundStyle(fg)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .padding(.horizontal, 16)
                .frame(maxWidth: kind == .big || wide ? .infinity : nil, minHeight: height)
                .background(RoundedRectangle(cornerRadius: 16).fill(bg))
                .background(DepthBand(radius: 16, drop: drop).fill(shadow))
                .offset(y: pressed ? 4 : 0)
                .padding(.bottom, 5)
                .animation(.linear(duration: 0.06), value: pressed)
        }

        private var fg: Color {
            switch kind {
            case .big: .white
            case .ghost: Theme.ink
            case .glassGhost: .white
            }
        }

        private var bg: Color {
            switch kind {
            case .big: enabled ? Theme.coral : Color(hex: "#cfc8dd")
            case .ghost: Color(hex: "#f1edf8")
            case .glassGhost: Color(red: 0.24, green: 0.22, blue: 0.36)
            }
        }

        private var shadow: Color {
            switch kind {
            case .big: enabled ? Color(hex: "#d9411f") : Color(hex: "#b3aac6")
            case .ghost: Theme.line
            case .glassGhost: Color.black.opacity(0.3)
            }
        }
    }
}

/// One referral source while passengers gather.
private struct CollectPart {
    let label: String
    let color: Color
    let count: Int
}

/// `COL` in the prototype: seat-filling animation state.
private final class CollectModel {
    let parts: [CollectPart]
    let seq: [Int]
    let cap: Int
    let balloons: Int
    let dur = 3.2
    var t = 0.0
    var shown = 0
    var counts: [Int]
    var done = false
    var last: Double?
    var lastTick = 0.0

    init(parts: [CollectPart], cap: Int, balloons: Int) {
        self.parts = parts
        self.cap = cap
        self.balloons = balloons
        var s: [Int] = []
        for (i, p) in parts.enumerated() { s += Array(repeating: i, count: max(0, p.count)) }
        s.shuffle()
        seq = Array(s.prefix(cap))
        counts = Array(repeating: 0, count: parts.count)
    }

    var k: Double { min(1, t / dur) }

    /// `updateCollect(dt)`.
    func advance(to date: Date) {
        let now = date.timeIntervalSinceReferenceDate
        let dt = last.map { min(0.05, max(0, now - $0)) } ?? 0
        last = now
        t += dt
        let kk = k
        let target = Int((kk * (2 - kk) * Double(seq.count)).rounded(.down))
        while shown < min(target, seq.count) {
            counts[seq[shown]] += 1
            shown += 1
            if now - lastTick >= 0.035 {
                lastTick = now
                SoundEngine.shared.play(.tick)
            }
        }
        if kk >= 1 && !done { done = true }
    }

    func skip() { t = dur }
}

/// The passenger-gathering card shown at the bottom over the home scene (`#collect`).
struct CollectView: View {
    @Environment(GameStore.self) private var store
    @State private var model: CollectModel?

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)
            if let model {
                TimelineView(.animation) { tl in
                    let _ = model.advance(to: tl.date)
                    let _ = share(model)
                    card(model)
                }
                .frame(maxWidth: 560)
                .background { GeometryReader { g in Color.clear.onAppear { store.collectScene.cardTop = g.frame(in: .global).minY } } }
                .opacity(store.leaving ? 0 : 1)
                .allowsHitTesting(!store.leaving)
            }
        }
        .padding(.horizontal, 8)
        .padding(.bottom, 10)
        .onAppear {
            if model == nil { model = makeModel() }
            SoundEngine.shared.crowd(true)
        }
        .onDisappear { SoundEngine.shared.crowd(false) }
    }

    /// The town's queue follows the seats as they fill.
    private func share(_ m: CollectModel) {
        store.collectScene.shown = m.shown
        store.collectScene.total = m.seq.count
    }

    private func makeModel() -> CollectModel? {
        guard let game = store.game else { return nil }
        let s = game.state
        let fl = s.flyingToday
        let m = game.market(price: s.price, capacity: s.capacityToday)
        var parts = [CollectPart(label: loc("collect.src.tourists", s.region.title), color: .white, count: m.base)]
        for p in m.parts { parts.append(CollectPart(label: Self.label(p.source), color: Self.color(p.source), count: p.count)) }
        return CollectModel(parts: parts, cap: s.capacityToday, balloons: fl.count)
    }

    static func label(_ s: PaxSource) -> String {
        switch s {
        case .tourists: loc("collect.src.tourists", currentRegion.title)
        case .hotel(let h): h.title
        case .guide: loc("collect.src.guide")
        case .influencer: loc("collect.src.influencer")
        case .popularity: loc("collect.src.popularity")
        }
    }

    static func color(_ s: PaxSource) -> Color {
        switch s {
        case .tourists: .white
        case .hotel(let h): Color(hex: h.color)
        case .guide: Color(hex: "#3ad0c0")
        case .influencer: Color(hex: "#ff6fa8")
        case .popularity: Color(hex: "#b79cff")
        }
    }

    /// Whether you fly the flagship yourself today (the go button then says "Take off").
    private var selfFlight: Bool {
        guard let s = store.state, let fb = s.balloon(s.flagship) else { return false }
        return s.isSelf(fb) && s.flyingToday.contains { $0.id == fb.id }
    }

    private func card(_ m: CollectModel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            header(m)
            timer(m)
            seats(m)
            sources(m)
            buttons(m)
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 24).fill(Theme.glass))
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24))
        .shadow(color: Color(red: 10 / 255, green: 5 / 255, blue: 30 / 255).opacity(0.4), radius: 15, y: 10)
    }

    private func header(_ m: CollectModel) -> some View {
        let title = !m.done ? loc("collect.title") : m.shown >= m.cap ? loc("collect.full") : loc("collect.ready")
        return HStack(alignment: .bottom, spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Theme.font(22, .bold, condensed: true))
                    .foregroundStyle(.white)
                Text(loc("collect.sub", eur(store.state?.price ?? 0), num(m.balloons)))
                    .font(Theme.font(13.5))
                    .foregroundStyle(.white.opacity(0.7))
            }
            Spacer(minLength: 0)
            Text(verbatim: "\(num(m.shown))/\(num(m.cap))")
                .font(Theme.font(42, .heavy, condensed: true))
                .foregroundStyle(Theme.sun)
                .lineLimit(1)
                .fixedSize()
        }
    }

    private func timer(_ m: CollectModel) -> some View {
        GeometryReader { g in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.white.opacity(0.15))
                Capsule().fill(Theme.sun).frame(width: g.size.width * CGFloat(1 - m.k))
            }
        }
        .frame(height: 8)
    }

    private func seats(_ m: CollectModel) -> some View {
        let small = m.cap > 60
        let side: CGFloat = small ? 10 : 16
        let cols = [GridItem(.adaptive(minimum: side, maximum: side), spacing: 4)]
        return LazyVGrid(columns: cols, alignment: .leading, spacing: 4) {
            ForEach(0..<max(0, m.cap), id: \.self) { i in
                seat(m, i, side: side, radius: small ? 3 : 5)
            }
        }
        // As tall as its rows (no empty band under a small fleet), at most 180 pt.
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxHeight: 180, alignment: .top)
        .clipped()
        // The seats are a picture of the count in the header.
        .accessibilityHidden(true)
    }

    private func seat(_ m: CollectModel, _ i: Int, side: CGFloat, radius: CGFloat) -> some View {
        let filled = i < m.shown && i < m.seq.count
        let color = filled ? m.parts[m.seq[i]].color : Color.white.opacity(0.12)
        return RoundedRectangle(cornerRadius: radius)
            .fill(color)
            .frame(width: side, height: side)
            .scaleEffect(filled ? 1.12 : 1)
            .animation(.easeOut(duration: 0.2), value: filled)
    }

    private func sources(_ m: CollectModel) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(Array(m.parts.enumerated()), id: \.offset) { i, p in
                HStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 4).fill(p.color).frame(width: 12, height: 12)
                    Text(p.label).font(Theme.font(14)).foregroundStyle(.white).lineLimit(1)
                    Spacer(minLength: 4)
                    Text(num(m.counts[i])).font(Theme.font(18, .bold, condensed: true)).foregroundStyle(.white)
                }
                .accessibilityElement(children: .combine)
            }
        }
    }

    /// `flyChoice`: whether who flies the flagship can still change today without changing which balloons take off.
    private var flyChoice: Bool {
        guard var g = store.game, let fb = g.state.balloon(g.state.flagship), g.state.licenseValid,
              g.state.local.strikeDay != g.state.day else { return false }
        let before = g.state.flyingToday.map(\.id)
        guard before.contains(fb.id) else { return false }
        g.setSelfFly(!g.state.local.selfFly)
        return g.state.flyingToday.map(\.id) == before
    }

    @ViewBuilder
    private func buttons(_ m: CollectModel) -> some View {
        if m.done && flyChoice { choiceButtons(m) } else { goButtons(m) }
    }

    /// Who flies is decided here: you and your pilots, or only the pilots. Today's choice is the big bright button on
    /// top; cancel and the other choice sit under it, slimmer.
    private func choiceButtons(_ m: CollectModel) -> some View {
        let me = store.state?.local.selfFly ?? true, solo = m.balloons == 1
        let selfTitle = loc(solo ? "collect.selfGo" : "collect.selfAndPilots")
        let pilotsTitle = loc(solo ? "collect.pilotGo" : "collect.onlyPilots")
        return VStack(spacing: 8) {
            Button(me ? selfTitle : pilotsTitle) { pick(selfFly: me) }
                .buttonStyle(ChunkyButtonStyle(kind: .big, height: 58))
            HStack(spacing: 10) {
                Button(loc("common.cancel")) {
                    SoundEngine.shared.play(.click)
                    store.cancelCollect()
                }
                .buttonStyle(ChunkyButtonStyle(kind: .glassGhost, height: 46))
                Button(me ? pilotsTitle : selfTitle) { pick(selfFly: !me) }
                    .buttonStyle(ChunkyButtonStyle(kind: .glassGhost, height: 46, wide: true))
            }
        }
    }

    private func pick(selfFly on: Bool) {
        SoundEngine.shared.play(.click)
        Haptics.press()
        store.act { $0.setSelfFly(on) }
        store.leaveCollect()
    }

    private func goButtons(_ m: CollectModel) -> some View {
        let go = !m.done ? loc("collect.skip") : selfFlight ? loc("collect.takeOff") : loc("collect.pilotsGo")
        return HStack(spacing: 10) {
            Button(loc("common.cancel")) {
                SoundEngine.shared.play(.click)
                store.cancelCollect()
            }
            .buttonStyle(ChunkyButtonStyle(kind: .glassGhost))
            Button(go) {
                SoundEngine.shared.play(.click)
                if !m.done { m.skip() } else { store.leaveCollect() }
            }
            .buttonStyle(ChunkyButtonStyle(kind: .big))
        }
    }
}
