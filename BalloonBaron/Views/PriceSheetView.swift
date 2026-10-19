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
                    result(g)
                    BigButton(title: loc("home.done")) { dismiss() }
                }
                .padding(20)
            }
            .background(Theme.paper.ignoresSafeArea())
            .onAppear {
                if baseIncome == nil { baseIncome = g.estimatedIncome().income }
            }
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
            VStack(spacing: 8) {
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("\(num(est.pax))/\(num(est.seats))")
                            .font(Theme.font(38, .heavy, condensed: true))
                            .foregroundStyle(Theme.ink)
                            .monospacedDigit()
                        Text(loc("psheet.filled"))
                            .font(Theme.font(13, .semibold))
                            .foregroundStyle(Theme.ink2)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 0) {
                        Text(eur(est.income))
                            .font(Theme.font(30, .heavy, condensed: true))
                            .foregroundStyle(Theme.ink)
                            .monospacedDigit()
                        delta(est.income)
                    }
                }
                TicketFillBar(fraction: Double(est.pax) / Double(max(1, est.seats)), height: 12)
            }
        }
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
        store.act { g in g.setPrice(g.state.price + d) }
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
            }
        }
        .frame(height: height)
    }
}
