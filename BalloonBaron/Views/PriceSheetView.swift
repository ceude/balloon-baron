import SwiftUI
import BalloonBaronCore

extension GameState {
    /// Seats rivals put in the sky today.
    var rivalSeatsToday: Int {
        var n = 0
        for r in local.rivals where r.alive {
            for i in r.flyToday where r.balloons.indices.contains(i) { n += r.balloons[i].capacity }
        }
        return n
    }
}

/// Ticket price panel: price, how tourists feel about it, and what today would bring.
struct PriceSheetView: View {
    @Environment(GameStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    /// Estimated income when the sheet opened, for the ▲/▼ delta.
    @State private var baseIncome: Int?

    /// Good value, a bit pricey, pricey, very pricey.
    static let zoneColors: [Color] = [Color(hex: "#3ad07a"), Color(hex: "#ffc23d"), Color(hex: "#ff8a3d"), Color(hex: "#ff5540")]

    var body: some View {
        if let g = store.game {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header
                    pricer(g.state)
                    rivals(g.state)
                    feelMeter(g.state.price)
                    mood(g)
                    resultNotes(g)
                }
                .padding(20)
            }
            // The result and the button stay pinned at the bottom of the sheet: at the half-height detent the
            // result used to sit under the button (v110), and the button half under the edge before that.
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 10) {
                    result(g)
                        .tutSpot("est")
                    BigButton(title: loc("home.done")) { dismiss() }
                        .tutSpot("psOk")
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 6)
                .background(Theme.paper.shadow(.drop(color: .black.opacity(0.08), radius: 6, y: -3)))
            }
            .background(Theme.paper.ignoresSafeArea())
            .onAppear {
                if baseIncome == nil { baseIncome = g.estimatedIncome().income }
            }
            // v122: the sheet hosts its own tutorial layer (day one's price step, the guided price lesson)
            .tutorialHost(minLineY: 70, present: { store.sheetSpots = $0 },
                          alive: { store.guided != nil || store.homeTutStep == "price" },
                          frame: { store.sheetTutFrame($0) }, onSkip: { store.skipTutorial() })
            .onDisappear { store.sheetSpots = [:] }
        }
    }

    private var header: some View {
        HStack {
            Text(loc("home.price"))
                .font(Theme.font(24, .heavy, condensed: true))
                .foregroundStyle(Theme.ink)
            Spacer()
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Theme.ink)
                    .frame(width: 36, height: 36)
                    .background(Theme.line.opacity(0.7), in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(loc("home.close"))
        }
    }

    private func pricer(_ s: GameState) -> some View {
        HStack(spacing: 12) {
            RepeatStepButton(icon: "minus", label: loc("psheet.minus")) { step(-5) }
                .tutSpot("pMinus")
            Text(eur(s.price))
                .font(Theme.font(44, .heavy, condensed: true))
                .foregroundStyle(Theme.ink)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .frame(maxWidth: .infinity)
            RepeatStepButton(icon: "plus", label: loc("psheet.plus")) { step(5) }
        }
    }

    @ViewBuilder
    private func rivals(_ s: GameState) -> some View {
        let alive = s.local.rivals.filter(\.alive)
        if !alive.isEmpty {
            VStack(alignment: .leading, spacing: 4) {
                ForEach(alive) { r in
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color(hex: r.colors.first ?? "#7a7f8c"))
                            .frame(width: 9, height: 9)
                        Text(r.name)
                            .font(Theme.font(14, .semibold))
                            .foregroundStyle(Theme.ink2)
                            .lineLimit(1)
                        Spacer(minLength: 6)
                        Text(eur(r.price))
                            .font(Theme.font(14, .bold))
                            .foregroundStyle(Theme.ink)
                            .monospacedDigit()
                    }
                }
            }
            .padding(12)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 14))
        }
    }

    private func feelMeter(_ price: Int) -> some View {
        let w = Rules.willing(Double(price))
        let zone = w >= 0.85 ? 0 : w >= 0.6 ? 1 : w >= 0.35 ? 2 : 3
        let pos = CGFloat(Game.feel(price: price)) / 100
        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(loc("psheet.feel"))
                    .font(Theme.font(15, .semibold))
                    .foregroundStyle(Theme.ink2)
                Spacer()
                Text(loc("psheet.feel.\(zone)"))
                    .font(Theme.font(17, .heavy, condensed: true))
                    .foregroundStyle(Self.zoneColors[zone])
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    HStack(spacing: 0) {
                        ForEach(0..<4, id: \.self) { i in
                            Rectangle().fill(Self.zoneColors[i])
                        }
                    }
                    .frame(height: 10)
                    .clipShape(Capsule())
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.white)
                        .frame(width: 6, height: 18)
                        .shadow(color: .black.opacity(0.4), radius: 2, y: 1)
                        .offset(x: min(max(0, geo.size.width * pos - 3), max(0, geo.size.width - 6)))
                }
                .frame(height: 18)
            }
            .frame(height: 18)
            .animation(.easeOut(duration: 0.15), value: pos)
            HStack {
                Text(loc("psheet.cheap"))
                Spacer()
                Text(loc("psheet.expensive"))
            }
            .font(Theme.font(12))
            .foregroundStyle(Theme.ink2)
        }
    }

    /// The day's tourists don't depend on price; price only changes how many pick you.
    private func mood(_ g: Game) -> some View {
        let tourists = g.touristsToday()
        let seats = g.state.capacityToday + g.state.rivalSeatsToday
        let key = seats > tourists ? "psheet.crowded" : "psheet.easy"
        return Text(loc(key, num(tourists), num(seats)))
            .font(Theme.font(15))
            .foregroundStyle(Theme.ink)
            .fixedSize(horizontal: false, vertical: true)
    }

    @ViewBuilder
    private func result(_ g: Game) -> some View {
        let est = g.estimatedIncome()
        if est.seats == 0 {
            Text(loc("home.noneFlying"))
                .font(Theme.font(16, .bold))
                .foregroundStyle(Theme.ink2)
        } else {
            VStack(spacing: 6) {
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("\(num(est.pax))/\(num(est.seats))")
                            .font(Theme.font(28, .heavy, condensed: true))
                            .lineLimit(1).minimumScaleFactor(0.6)
                            .foregroundStyle(Theme.ink)
                            .monospacedDigit()
                            // v122: a lower price counts the passengers up: the number pops and "+N" rises
                            .paxPop(pax: est.pax, seats: est.seats, price: g.state.price, alignment: .trailing)
                        Text(loc("psheet.filled"))
                            .font(Theme.font(13, .semibold))
                            .foregroundStyle(Theme.ink2)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 0) {
                        Text(eur(est.income))
                            .font(Theme.font(26, .heavy, condensed: true))
                            .lineLimit(1).minimumScaleFactor(0.6)
                            .foregroundStyle(Theme.ink)
                            .monospacedDigit()
                        delta(est.income)
                    }
                }
                TicketFillBar(fraction: Double(est.pax) / Double(max(1, est.seats)), height: 10)
            }
        }
    }

    /// Why the sum is not simply seats × price; scrolls with the page, under the pinned result.
    @ViewBuilder
    private func resultNotes(_ g: Game) -> some View {
        let est = g.estimatedIncome()
        let notes = est.seats > 0 ? notes(g, est) : []
        if !notes.isEmpty {
            Text(notes.joined(separator: " "))
                .font(Theme.font(12.5))
                .foregroundStyle(Theme.ink2)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func notes(_ g: Game, _ est: (pax: Int, seats: Int, income: Int)) -> [String] {
        let s = g.state, fl = s.flyingToday
        var out: [String] = []
        if fl.contains(where: { s.isSelf($0) }) && est.pax > 0 {
            out.append(loc("psheet.founderNote", percent(Rules.founderPremium), eur(est.income - est.pax * s.price)))
        }
        if s.local.docDay == s.day && fl.contains(where: { $0.id == s.flagship }) { out.append(loc("psheet.docNote")) }
        return out
    }

    @ViewBuilder
    private func delta(_ income: Int) -> some View {
        let d = income - (baseIncome ?? income)
        if d > 0 {
            Text("▲ +" + eur(d))
                .font(Theme.font(14, .bold))
                .foregroundStyle(Theme.green)
        } else if d < 0 {
            Text("▼ −" + eur(-d))
                .font(Theme.font(14, .bold))
                .foregroundStyle(Theme.red)
        } else {
            Text(loc("psheet.estIncome"))
                .font(Theme.font(13, .semibold))
                .foregroundStyle(Theme.ink2)
        }
    }

    private func step(_ d: Int) {
        let before = store.state?.price
        store.act { g in g.setPrice(g.state.price + d) }
        if store.state?.price != before { Haptics.tick() }
        store.tutPriceChanged()
    }
}

/// Round −/+ button that repeats while held.
struct RepeatStepButton: View {
    let icon: String
    let label: String
    let action: () -> Void
    @State private var repeater: Task<Void, Never>?
    /// Resets on its own when the touch is cancelled (e.g. the sheet starts scrolling).
    @GestureState private var pressed = false

    var body: some View {
        Image(systemName: icon)
            .font(.system(size: 22, weight: .bold))
            .foregroundStyle(Theme.ink)
            .frame(width: 56, height: 56)
            .background(Theme.line.opacity(0.7), in: Circle())
            .scaleEffect(pressed ? 0.92 : 1)
            .contentShape(Circle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .updating($pressed) { _, state, _ in state = true }
            )
            .onChange(of: pressed) { _, now in
                if now { start() } else { stop() }
            }
            .onDisappear { stop() }
            .accessibilityElement()
            .accessibilityLabel(label)
            .accessibilityAddTraits(.isButton)
            .accessibilityAction { action() }
    }

    private func start() {
        guard repeater == nil else { return }
        action()
        let tick = action
        repeater = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 350_000_000)
            while !Task.isCancelled {
                tick()
                try? await Task.sleep(nanoseconds: 70_000_000)
            }
        }
    }

    private func stop() {
        repeater?.cancel()
        repeater = nil
    }
}

/// Green fill bar for seats sold.
struct TicketFillBar: View {
    let fraction: Double
    var height: CGFloat = 8

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.line)
                Capsule()
                    .fill(Theme.green)
                    .frame(width: geo.size.width * CGFloat(min(1, max(0, fraction))))
                    // v122: the bar fills as the passengers count up
                    .animation(.easeOut(duration: 0.45), value: fraction)
            }
        }
        .frame(height: height)
    }
}

/// v122 (`paxBump`): when the price changes and the passengers you'd get go up, the number pops and a green "+N"
/// rises beside it and fades.
struct PaxPop: ViewModifier {
    let pax: Int, seats: Int, price: Int
    var alignment: Alignment = .topTrailing
    @State private var last: [Int]?
    @State private var bump = false
    @State private var pops: [Pop] = []

    struct Pop: Identifiable { let id = UUID(); let n: Int }

    func body(content: Content) -> some View {
        content
            .scaleEffect(bump ? 1.3 : 1, anchor: .leading)
            .overlay(alignment: alignment) {
                ZStack {
                    ForEach(pops) { p in PopText(n: p.n) }
                }
                .allowsHitTesting(false)
            }
            .onChange(of: price) { _, _ in check() }
            .onAppear { last = [pax, seats, price] }
    }

    private func check() {
        defer { last = [pax, seats, price] }
        guard let l = last, l[1] == seats, l[2] != price, pax > l[0] else { return }
        withAnimation(.easeOut(duration: 0.18)) { bump = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { withAnimation(.easeIn(duration: 0.25)) { bump = false } }
        let p = Pop(n: pax - l[0])
        pops.append(p)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) { pops.removeAll { $0.id == p.id } }
    }

    private struct PopText: View {
        let n: Int
        @State private var up = false
        @State private var gone = false

        var body: some View {
            Text(loc("price.paxUp", num(n)))
                .font(Theme.font(20, .heavy, condensed: true))
                .foregroundStyle(Color(hex: "#3ac078"))
                .shadow(color: .black.opacity(0.25), radius: 3, y: 2)
                .fixedSize()
                .offset(x: 0, y: up ? -26 : 8)
                .opacity(gone ? 0 : up ? 1 : 0)
                .onAppear {
                    withAnimation(.easeOut(duration: 0.3)) { up = true }
                    withAnimation(.easeIn(duration: 0.8).delay(0.4)) { gone = true }
                }
        }
    }
}

extension View {
    func paxPop(pax: Int, seats: Int, price: Int, alignment: Alignment = .topTrailing) -> some View {
        modifier(PaxPop(pax: pax, seats: seats, price: price, alignment: alignment))
    }
}
