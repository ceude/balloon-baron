import SwiftUI
import BalloonBaronCore

/// v124: Bristol's Night Glow card (`glowCard`): once per festival the balloons stand on the field at night and fire
/// their burners to music, then fireworks. Opened from the festival alert, the fleet page and the popularity rows.
struct GlowCardView: View {
    @Environment(GameStore.self) private var store

    var body: some View {
        ModalCard {
            if let g = store.game {
                let st = g.glowState
                CardText.title(loc(st == .booked ? "glow.bookedTitle" : "glow.title"))
                if st == .booked {
                    CardText.lead(loc("glow.bookedBody", num(g.glowFleet.count)))
                    closeButton(loc("show.ok"), big: true)
                } else {
                    CardText.lead(loc("glow.intro"))
                    VStack(alignment: .leading, spacing: 4) {
                        Text(loc("show.gainsTitle")).font(Theme.font(14, .bold)).foregroundStyle(Theme.ink)
                        ForEach([loc("glow.gainRep", "+" + starsValue(Glow.rep * 4)), loc("glow.gainPaper"), loc("glow.gainGoal")], id: \.self) { line in
                            HStack(alignment: .firstTextBaseline, spacing: 6) {
                                Text("•").foregroundStyle(Theme.coral)
                                Text(line).fixedSize(horizontal: false, vertical: true)
                            }
                            .font(Theme.font(13.5)).foregroundStyle(Theme.ink)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(Color(hex: "#fff1e6"), in: RoundedRectangle(cornerRadius: 14))
                    if st == .ok {
                        Button(loc("glow.confirm", eur(Glow.cost))) {
                            SoundEngine.shared.play(.coin)
                            store.act { _ = $0.bookGlow() }
                        }
                        .buttonStyle(ChunkyButtonStyle(kind: .big, wide: true))
                        closeButton(loc("show.cancelBtn"), big: false)
                    } else {
                        Text(GlowCardView.why(st, g))
                            .font(Theme.font(14, .bold)).foregroundStyle(Theme.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(12)
                            .background(Theme.red.opacity(0.1), in: RoundedRectangle(cornerRadius: 14))
                        closeButton(loc("home.close"), big: true)
                    }
                }
            }
        }
    }

    private func closeButton(_ title: String, big: Bool) -> some View {
        Button {
            SoundEngine.shared.play(.click)
            store.closeGlowCard()
        } label: { Text(title).frame(maxWidth: .infinity) }
        .buttonStyle(ChunkyButtonStyle(kind: big ? .big : .ghost, wide: true))
    }

    /// Why the glow can't be booked, or what it costs.
    static func why(_ st: GlowState, _ g: Game) -> String {
        switch st {
        case .noFestival: loc("glow.why.nofest")
        case .booked: loc("glow.why.booked")
        case .done: loc("glow.why.done")
        case .show: loc("glow.why.show")
        case .few: loc("glow.why.few", num(Glow.minBalloons))
        case .cash: loc("glow.why.cash", eur(Glow.cost))
        case .ok: loc("glow.why.ok")
        }
    }

    /// A row on the pages while Bristol's festival is on.
    static func offered(_ g: Game) -> Bool { g.state.region == .bri && g.state.fiesta != nil }

    /// The fleet page's short state.
    static func short(_ st: GlowState, _ g: Game) -> String {
        switch st {
        case .ok: eur(Glow.cost)
        case .booked: loc("glow.short.booked")
        case .done: loc("glow.short.done")
        case .few: loc("glow.short.few", num(Glow.minBalloons))
        case .show: loc("glow.short.show")
        default: loc("glow.short.cash", eur(Glow.cost))
        }
    }
}
