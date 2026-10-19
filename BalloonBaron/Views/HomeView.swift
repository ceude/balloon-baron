import SwiftUI
import BalloonBaronCore

struct HomeView: View {
    @Environment(GameStore.self) private var store
    @State private var confirmRed = false

    var body: some View {
        if let game = store.game {
            let s = game.state
            let w = s.weather
            ScrollView {
                VStack(spacing: 14) {
                    hud(s)
                    if let w { weatherCard(w, winter: s.winter != nil) }
                    if let m = w?.mission { missionCard(m, s) }
                    marketCard(game)
                    priceCard(s)
                    actions(s)
                    #if DEBUG
                    Button(loc("debug.reset")) { store.resetForTesting() }
                        .font(Theme.font(13))
                        .foregroundStyle(.white.opacity(0.7))
                        .padding(.top, 8)
                    #endif
                }
                .padding(16)
            }
            .alert(loc("home.redConfirm"), isPresented: $confirmRed) {
                Button(loc("home.redFly"), role: .destructive) { store.fly() }
                Button(loc("common.cancel"), role: .cancel) {}
            } message: {
                Text(loc("home.redConfirmBody"))
            }
        }
    }

    private func hud(_ s: GameState) -> some View {
        HStack(spacing: 8) {
            chip(loc("hud.day", num(s.day)))
            Spacer()
            chip(eur(s.cash))
            chip(starsText(s.rep), color: Theme.sun)
        }
    }

    private func chip(_ text: String, color: Color = .white) -> some View {
        Text(text)
            .font(Theme.font(17, .bold, condensed: true))
            .foregroundStyle(color)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Theme.glass, in: Capsule())
    }

    private func weatherCard(_ w: Weather, winter: Bool) -> some View {
        card {
            HStack(spacing: 10) {
                Circle().fill(Theme.flagColor(w.flag)).frame(width: 14, height: 14)
                Text(w.flag.title).font(Theme.font(22, .heavy, condensed: true)).foregroundStyle(Theme.ink)
                Spacer()
                if winter {
                    Text(loc("home.winter")).font(Theme.font(13, .bold)).foregroundStyle(Theme.ink2)
                }
            }
            Text(w.flag.note).font(Theme.font(15)).foregroundStyle(Theme.ink2)
            Text(loc("home.wind", num(w.surfaceWind))).font(Theme.font(14, .semibold)).foregroundStyle(Theme.ink2)
        }
    }

    private func missionCard(_ m: Mission, _ s: GameState) -> some View {
        let size = s.balloon(s.flagship)?.size ?? .S
        return card {
            Text(loc("home.mission", m.title, eur(m.reward(for: size)))).font(Theme.font(19, .heavy, condensed: true)).foregroundStyle(Theme.coral)
            Text(m.detail).font(Theme.font(15)).foregroundStyle(Theme.ink2)
            if !s.flyingSelf {
                Button(loc("home.missionSelf")) { store.act { $0.setSelfFly(true) } }
                    .font(Theme.font(14, .bold))
                    .foregroundStyle(Theme.coral)
            }
        }
    }

    private func marketCard(_ g: Game) -> some View {
        let s = g.state
        let rivalSeats = s.rivals.filter(\.alive).reduce(0) { acc, r in acc + r.flyToday.reduce(0) { $0 + r.balloons[$1].capacity } }
        return card {
            HStack {
                stat(loc("home.tourists"), num(s.demand ?? 0))
                stat(loc("home.seats"), num(s.capacityToday))
                stat(loc("home.rivalSeats"), num(rivalSeats))
            }
            if !s.licenseValid {
                Text(loc("home.licenseExpired", eur(Rules.recertCost))).font(Theme.font(14, .bold)).foregroundStyle(Theme.red)
                Button(loc("home.renew") + " " + eur(Rules.recertCost)) { store.act { $0.renewLicense() } }
                    .font(Theme.font(14, .bold))
                    .foregroundStyle(Theme.coral)
                    .disabled(s.cash < Rules.recertCost)
            } else {
                Text(loc("home.license", num(s.licenseDaysLeft))).font(Theme.font(13)).foregroundStyle(Theme.ink2)
            }
            if s.flyingToday.contains(where: { s.isSelf($0) }) {
                Text(loc("home.founderBonus")).font(Theme.font(13, .semibold)).foregroundStyle(Theme.green)
            }
            if s.daysSinceSelfFly > Rules.absentGraceDays - 2 && !s.flyingSelf {
                Text(loc("home.absent", num(s.daysSinceSelfFly))).font(Theme.font(13, .bold)).foregroundStyle(Theme.yellow)
            }
        }
    }

    private func stat(_ label: String, _ value: String) -> some View {
        VStack(spacing: 2) {
            Text(value).font(Theme.font(26, .heavy, condensed: true)).foregroundStyle(Theme.ink)
            Text(label).font(Theme.font(12, .semibold)).foregroundStyle(Theme.ink2).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    private func priceCard(_ s: GameState) -> some View {
        card {
            HStack {
                Text(loc("home.price")).font(Theme.font(17, .bold)).foregroundStyle(Theme.ink)
                Spacer()
                stepButton("minus") { store.act { $0.setPrice(s.price - 5) } }
                Text(eur(s.price))
                    .font(Theme.font(26, .heavy, condensed: true))
                    .foregroundStyle(Theme.ink)
                    .frame(minWidth: 84)
                    .monospacedDigit()
                stepButton("plus") { store.act { $0.setPrice(s.price + 5) } }
            }
        }
    }

    private func stepButton(_ icon: String, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .bold))
                .frame(width: 44, height: 44)
                .foregroundStyle(Theme.ink)
                .background(Theme.line.opacity(0.6), in: Circle())
        }
        .buttonStyle(.plain)
    }

    private func actions(_ s: GameState) -> some View {
        let selfFlight = s.flyingToday.contains { s.isSelf($0) }
        return VStack(spacing: 10) {
            BigButton(title: loc(selfFlight ? "home.fly" : "home.send")) {
                if s.weather?.flag == .red { confirmRed = true } else { store.fly() }
            }
            .disabled(s.flyingToday.isEmpty)
            .opacity(s.flyingToday.isEmpty ? 0.5 : 1)
            BigButton(title: loc("home.skip"), style: .ghost) { store.fly(skip: true) }
        }
    }

    private func card<C: View>(@ViewBuilder _ content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 8, content: content)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(Theme.paper, in: RoundedRectangle(cornerRadius: 20))
    }
}
