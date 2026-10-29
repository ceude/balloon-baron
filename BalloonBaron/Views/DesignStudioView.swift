import SwiftUI
import BalloonBaronCore

/// Workshop design studio (`showDesigner`): pick a pattern, three colours and a name.
struct DesignStudioView: View {
    @Environment(GameStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var pattern: Pattern = .zigzag
    /// A shaped envelope from the bazaar, or nil for the classic one.
    @State private var shape: EnvelopeShape?
    @State private var colors: [String] = ["#ff5e3a", "#ffc23d", "#ffffff"]
    @State private var name = ""
    @State private var ready = false
    /// The preview turns under a finger (v123.6): angle and speed in radians, the drag's last point, and whether a
    /// fast spin has lit the burner.
    @State private var spin = 0.0
    @State private var spinSpeed = 0.0
    @State private var dragLast: (x: CGFloat, t: Date)?
    @State private var burning = false
    @State private var coast: Task<Void, Never>?
    /// A locked item tapped here: chosen once it is bought.
    @State private var pendingShape: EnvelopeShape?
    @State private var pendingPattern: Pattern?

    private static let maxName = 22

    var body: some View {
        ZStack {
            Theme.paper.ignoresSafeArea()
            if let game = store.game {
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        Text(loc("studio.title"))
                            .font(Theme.font(28, .heavy, condensed: true))
                            .foregroundStyle(Theme.ink)
                        preview(game)
                        patternPicker
                        shapePicker
                        colorRow(0, label: loc("studio.main"))
                        colorRow(1, label: loc("studio.patternColor"))
                        colorRow(2, label: loc("studio.accent"))
                        nameField
                        FleetUI.Hint(loc("studio.hint"))
                        buttons(game)
                    }
                    .padding(20)
                    .overlay(alignment: .topTrailing) { CardCloseX { dismiss() } }
                }
            }
            // v123.6: a locked pattern or shape opens its purchase card here, over the studio, not instead of it.
            if let k = store.storeItem {
                StoreItemView(item: k).transition(.opacity)
            }
        }
        .animation(.easeOut(duration: 0.2), value: store.storeItem)
        .onAppear {
            store.studioOpen = true
            setup()
        }
        .onDisappear {
            store.studioOpen = false
            stopSpin()
        }
        .onChange(of: store.storeItem) { _, item in
            guard item == nil else { return }
            if let k = pendingShape, !locked(k.storeItem) { shape = k }
            if let p = pendingPattern, !locked(p.storeItem) { pattern = p }
            pendingShape = nil
            pendingPattern = nil
        }
    }

    /// First unused pattern in the company's colours, like the prototype.
    private func setup() {
        guard !ready, let s = store.state else { return }
        ready = true
        let used = Set(s.designs.map(\.pattern))
        pattern = Pattern.allCases.first { !used.contains($0) && !$0.premium } ?? .zigzag
        let main = s.colors.first ?? "#ff5e3a"
        let second = s.colors.count > 1 ? s.colors[1] : "#ffc23d"
        colors = [main, second, "#ffffff"]
    }

    private func verdict(_ score: Int) -> String {
        let level = score >= 80 ? 4 : score >= 60 ? 3 : score >= 40 ? 2 : 1
        return loc("studio.verdict.\(level)")
    }

    private func preview(_ game: Game) -> some View {
        let score = game.designScore(pattern: pattern, colors: colors, shape: shape)
        return HStack(alignment: .center, spacing: 16) {
            // In full volume (v110), as it will fly.
            // v123.6: a finger turns it round its axis; spun fast, its burner lights with a faint roar and hum.
            TimelineView(.animation(paused: !burning)) { _ in
                Canvas { ctx, size in
                    ScenePainter.designBalloon3d(&ctx, x: size.width / 2, y: size.height - 4, r: size.height * 0.28 / 0.86, colors: colors,
                                                 burn: burning, design: Design(preview: pattern, colors: colors, shape: shape), spin: spin)
                }
            }
            .frame(width: 140, height: 178)
            .contentShape(Rectangle())
            .simultaneousGesture(spinGesture)
            .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 6) {
                Text(loc("studio.creativity"))
                    .font(Theme.font(14, .bold))
                    .foregroundStyle(Theme.ink2)
                Text(num(score))
                    .font(Theme.font(44, .heavy, condensed: true))
                    .foregroundStyle(Theme.ink)
                    .monospacedDigit()
                Capsule()
                    .fill(Theme.line)
                    .frame(height: 8)
                    .overlay(alignment: .leading) {
                        GeometryReader { g in
                            Capsule()
                                .fill(LinearGradient(colors: [Theme.sun, Theme.coral], startPoint: .leading, endPoint: .trailing))
                                .frame(width: g.size.width * CGFloat(score) / 100)
                        }
                    }
                Text(verdict(score))
                    .font(Theme.font(13, .semibold))
                    .foregroundStyle(Theme.ink2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .animation(.easeOut(duration: 0.2), value: score)
    }

    /// About 60 points of drag turn it one radian; the speed is smoothed so a flick reads as a flick.
    private var spinGesture: some Gesture {
        DragGesture(minimumDistance: 2)
            .onChanged { v in
                coast?.cancel()
                let now = Date()
                if let last = dragLast {
                    let dt = max(now.timeIntervalSince(last.t), 1.0 / 240)
                    let d = Double(v.location.x - last.x) / 60
                    spin += d
                    spinSpeed = spinSpeed * 0.6 + (d / dt) * 0.4
                    spinTick(now)
                }
                dragLast = (v.location.x, now)
            }
            .onEnded { _ in
                dragLast = nil
                startCoast()
            }
    }

    /// Let go, it turns on and slows down, like a balloon on its rope.
    private func startCoast() {
        coast?.cancel()
        coast = Task { @MainActor in
            var last = Date()
            while !Task.isCancelled, abs(spinSpeed) > 0.05 {
                try? await Task.sleep(nanoseconds: 16_000_000)
                let now = Date(), dt = now.timeIntervalSince(last)
                last = now
                spin += spinSpeed * dt
                spinSpeed *= pow(0.25, dt)
                spinTick(now)
            }
            spinSpeed = 0
            setBurn(false)
        }
    }

    /// Faster than about one and a half turns a second, the burner fires.
    private func spinTick(_ now: Date) {
        setBurn(abs(spinSpeed) > 9)
        if burning { Haptics.studioBurner(at: now.timeIntervalSinceReferenceDate) }
    }

    private func setBurn(_ on: Bool) {
        guard on != burning else { return }
        burning = on
        SoundEngine.shared.burner(on, level: 0.3)
    }

    private func stopSpin() {
        coast?.cancel()
        spinSpeed = 0
        setBurn(false)
    }

    private func label(_ text: String) -> some View {
        Text(text)
            .font(Theme.font(14, .bold))
            .foregroundStyle(Theme.ink2)
    }

    private var patternPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            label(loc("studio.pattern"))
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                ForEach(Pattern.allCases, id: \.self) { p in
                    patternButton(p)
                }
            }
        }
    }

    /// Locked bazaar items open their purchase sheet.
    private func locked(_ k: StoreItem?) -> Bool { k.map { !(store.state?.owned($0) ?? false) } ?? false }

    private func openStore(_ k: StoreItem) {
        SoundEngine.shared.play(.click)
        store.storeItem = k
    }

    private var shapePicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            label(loc("studio.shape"))
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 2), spacing: 8) {
                ForEach([nil] + EnvelopeShape.allCases.map { Optional($0) }, id: \.self) { k in
                    choice(k.map { (locked($0.storeItem) ? "" : "✦ ") + $0.title } ?? loc("studio.classic"), lock: k.map { locked($0.storeItem) } ?? false, on: shape == k) {
                        if let k, locked(k.storeItem) { pendingShape = k; openStore(k.storeItem) } else { shape = k }
                    }
                }
            }
        }
    }

    private func choice(_ title: String, lock: Bool = false, on: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if lock { LockGlyph(size: 12) }
                Text(title)
            }
                .font(Theme.font(15, .bold, condensed: true))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity, minHeight: 38)
                .foregroundStyle(on ? Color.white : Theme.ink)
                .background(on ? Theme.coral : Color.white, in: RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(on ? Color.clear : Theme.line, lineWidth: 2))
        }
        .buttonStyle(.plain)
    }

    private func patternButton(_ p: Pattern) -> some View {
        let on = p == pattern
        return Button {
            if locked(p.storeItem), let k = p.storeItem { pendingPattern = p; openStore(k) } else { pattern = p }
        } label: {
            HStack(spacing: 4) {
                if p.premium && locked(p.storeItem) { LockGlyph(size: 12) }
                Text((p.premium && !locked(p.storeItem) ? "✦ " : "") + p.title)
            }
                .font(Theme.font(15, .bold, condensed: true))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity, minHeight: 38)
                .foregroundStyle(on ? Color.white : Theme.ink)
                .background(on ? Theme.coral : Color.white, in: RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(on ? Color.clear : Theme.line, lineWidth: 2))
        }
        .buttonStyle(.plain)
    }

    private func colorRow(_ index: Int, label text: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            label(text)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 6), spacing: 8) {
                ForEach(Studio.swatches, id: \.self) { hex in
                    swatch(hex, index: index)
                }
            }
        }
    }

    private func swatch(_ hex: String, index: Int) -> some View {
        let on = index < colors.count && colors[index] == hex
        return Button {
            guard index < colors.count else { return }
            colors[index] = hex
        } label: {
            Circle()
                .fill(Color(hex: hex))
                .frame(width: 36, height: 36)
                .overlay(Circle().stroke(Theme.line, lineWidth: 1))
                .overlay(Circle().stroke(Theme.ink, lineWidth: on ? 3 : 0).padding(-3))
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(hex)
    }

    private var nameField: some View {
        TextField(loc("studio.placeholder"), text: $name)
            .font(Theme.font(18, .semibold))
            .padding(12)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.line, lineWidth: 2))
            .submitLabel(.done)
            .onChange(of: name) { _, value in
                if value.count > Self.maxName { name = String(value.prefix(Self.maxName)) }
            }
    }

    private func buttons(_ game: Game) -> some View {
        let cost = game.designCost
        let short = game.state.cash < cost
        return VStack(spacing: 10) {
            BigButton(title: cost > 0 ? loc("studio.create", eur(cost)) : loc("studio.createFree")) {
                let n = name, p = pattern, c = colors, sh = shape
                store.act { _ = $0.createDesign(name: n, pattern: p, colors: c, shape: sh) }
                dismiss()
            }
            .disabled(short)
            .opacity(short ? 0.5 : 1)
            BigButton(title: loc("common.cancel"), style: .ghost) { dismiss() }
        }
    }
}
