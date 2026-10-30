import SwiftUI
import BalloonBaronCore

/// The prototype's `.big` / `.ghost` buttons: chunky, with a solid drop shadow that sinks when pressed.
struct ChunkyButtonStyle: ButtonStyle {
    /// `danger`: a big red button for what can't be undone (selling a balloon; `.big.danger` in the prototype).
    enum Kind { case big, ghost, glassGhost, danger }
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
                .font(kind == .big || kind == .danger ? Theme.font(22, .heavy, condensed: true) : Theme.font(18, .bold, condensed: true))
                .foregroundStyle(fg)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .padding(.horizontal, 16)
                .frame(maxWidth: kind == .big || kind == .danger || wide ? .infinity : nil, minHeight: height)
                .background(RoundedRectangle(cornerRadius: 16).fill(bg))
                .background(DepthBand(radius: 16, drop: drop).fill(shadow))
                .offset(y: pressed ? 4 : 0)
                .padding(.bottom, 5)
                .animation(.linear(duration: 0.06), value: pressed)
        }

        private var fg: Color {
            switch kind {
            case .big, .danger: .white
            case .ghost: Theme.ink
            case .glassGhost: .white
            }
        }

        private var bg: Color {
            switch kind {
            case .big: enabled ? Theme.coral : Color(hex: "#cfc8dd")
            case .danger: enabled ? Theme.red : Color(hex: "#cfc8dd")
            case .ghost: Color(hex: "#f1edf8")
            case .glassGhost: Color(red: 0.24, green: 0.22, blue: 0.36)
            }
        }

        private var shadow: Color {
            switch kind {
            case .big: enabled ? Color(hex: "#d9411f") : Color(hex: "#b3aac6")
            case .danger: enabled ? Color(hex: "#a8302a") : Color(hex: "#b3aac6")
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

    /// v125.3: a contract morning: the jeeps fetch the group first (2.6 s), and its seats (part 0) fill first.
    let delay: Double

    init(parts: [CollectPart], cap: Int, balloons: Int, group: Bool = false, delay: Double = 0) {
        self.parts = parts
        self.cap = cap
        self.balloons = balloons
        self.delay = delay
        var s: [Int] = []
        for (i, p) in parts.enumerated() where !(group && i == 0) { s += Array(repeating: i, count: max(0, p.count)) }
        s.shuffle()
        if group { s = Array(repeating: 0, count: max(0, parts[0].count)) + s }
        seq = Array(s.prefix(cap))
        counts = Array(repeating: 0, count: parts.count)
    }

    var k: Double { min(1, max(0, t - delay) / dur) }

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

    func skip() { t = dur + delay }
}

/// The passenger-gathering card shown at the bottom over the home scene (`#collect`).
struct CollectView: View {
    @Environment(GameStore.self) private var store
    @State private var model: CollectModel?
    /// v121.12: nobody boarded; flying empty earns nothing, so it asks first.
    @State private var emptyAsk = false

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
            // Boarding scene off in the settings: the card fills at once, without the crowd.
            if store.collectAnimation { SoundEngine.shared.crowd(true) } else { model?.skip() }
        }
        .onDisappear { SoundEngine.shared.crowd(false) }
        // v122.5: the game's own card, not the system alert
        .modifier(GameAlert(shown: $emptyAsk, title: loc("collect.empty.title"), message: loc("collect.empty.lead"),
                            primary: loc("collect.empty.price"), secondary: loc("collect.empty.go"),
                            onPrimary: { store.cancelCollect(); store.showPriceSheet = true },
                            onSecondary: { store.leaveCollect() }))
    }

    private func leave() {
        if let m = model, m.shown == 0 { emptyAsk = true } else { store.leaveCollect() }
    }

    /// The town's queue follows the seats as they fill.
    private func share(_ m: CollectModel) {
        store.collectScene.shown = store.collectAnimation ? m.shown : 0
        store.collectScene.total = m.seq.count
    }

    private func makeModel() -> CollectModel? {
        guard let game = store.game else { return nil }
        let s = game.state
        let fl = s.flyingToday
        // v125: a tour group booked for today is seated first; the market fills the rest
        let held = s.contractHeld(capacity: s.capacityToday)
        let m = game.market(price: s.price, capacity: s.capacityToday - held)
        var parts = [CollectPart(label: loc("collect.src.tourists", s.region.title), color: .white, count: m.base)]
        for p in m.parts { parts.append(CollectPart(label: Self.label(p.source), color: Self.color(p.source), count: p.count)) }
        guard held > 0, let k = s.contractToday, let place = ContractPlace.of(s.region) else {
            store.collectScene.group = nil
            return CollectModel(parts: parts, cap: s.capacityToday, balloons: fl.count)
        }
        parts.insert(CollectPart(label: loc("collect.src.contract", k.owner.company), color: Color(hex: k.owner.color), count: held), at: 0)
        store.collectScene.group = store.collectAnimation
            ? CollectScene.Group(n: held, color: k.owner.color, jeeps: min(max(Int((Double(held) / 10).rounded(.up)), 1), 3), road: place.town) : nil
        store.collectScene.ctrT0 = nil
        return CollectModel(parts: parts, cap: s.capacityToday, balloons: fl.count, group: true, delay: store.collectAnimation ? 2.6 : 0)
    }

    static func label(_ s: PaxSource) -> String {
        switch s {
        case .tourists: loc("collect.src.tourists", currentRegion.title)
        case .hotel(let h): h.title
        case .guide: loc("collect.src.guide")
        case .influencer: loc("collect.src.influencer")
        case .popularity: loc("collect.src.popularity")
        case .show: loc("collect.src.show")
        }
    }

    static func color(_ s: PaxSource) -> Color {
        switch s {
        case .tourists: .white
        case .hotel(let h): Color(hex: h.color)
        case .guide: Color(hex: "#3ad0c0")
        case .influencer: Color(hex: "#ff6fa8")
        case .popularity: Color(hex: "#b79cff")
        case .show: Color(hex: "#ffc23d")
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

    /// `flyChoice` (v121.6): who flies the flagship can always be chosen at the end of boarding (a TestFlight player
    /// missed the two buttons when no pilot was spare). How many balloons go up either way; nil when there's no choice.
    private var flyChoice: (me: Int, pilots: Int)? {
        guard let g0 = store.game, let fb = g0.state.balloon(g0.state.flagship), g0.state.licenseValid,
              g0.state.local.strikeDay != g0.state.day else { return nil }
        var a = g0, b = g0
        a.setSelfFly(true)
        b.setSelfFly(false)
        let me = a.state.flyingToday, pilots = b.state.flyingToday.count
        guard me.contains(where: { $0.id == fb.id }), pilots > 0 else { return nil }
        return (me.count, pilots)
    }

    @ViewBuilder
    private func buttons(_ m: CollectModel) -> some View {
        if m.done, let c = flyChoice { choiceButtons(m, down: c.me - c.pilots) } else { goButtons(m) }
    }

    /// Who flies is decided here: you and your pilots, or only the pilots. Today's choice is the big bright button on
    /// top; cancel and the other choice sit under it, slimmer.
    private func choiceButtons(_ m: CollectModel, down: Int) -> some View {
        let me = store.state?.local.selfFly ?? true, solo = m.balloons == 1
        let selfTitle = loc(solo ? "collect.selfGo" : "collect.selfAndPilots")
        // With no spare pilot, letting the pilots fly leaves a balloon on the ground; the button says so.
        let pilotsTitle = loc(solo ? "collect.pilotGo" : "collect.onlyPilots") + (down > 0 ? " · " + loc("collect.downCount", num(down)) : "")
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
        leave()
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
                if !m.done { m.skip() } else { leave() }
            }
            .buttonStyle(ChunkyButtonStyle(kind: .big))
        }
    }
}
