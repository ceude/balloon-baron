import SwiftUI
import BalloonBaronCore

/// v111: the Balloon Show's card (`showCard`): what it costs (every balloon that can fly), what it brings, and the
/// wait until the next one. Booked, it plays over the town that night.
struct ShowCardView: View {
    @Environment(GameStore.self) private var store

    var body: some View {
        ModalCard {
            if let g = store.game {
                let st = g.showState, n = g.showFleet.count
                CardText.title(loc("show.cardTitle"))
                CardText.lead(loc("show.lead", eur(Rules.showPerBalloon), num(Int(Rules.showPax))))
                Text(st == .ok ? loc("show.ready", num(n), eur(g.showCost)) : ShowCardView.why(st, g))
                    .font(Theme.font(14, .bold))
                    .foregroundStyle(st == .ok ? Theme.ink : Theme.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background((st == .ok ? Theme.sun.opacity(0.18) : Theme.red.opacity(0.1)), in: RoundedRectangle(cornerRadius: 14))
                if st == .ok {
                    Button(loc("show.book", eur(g.showCost))) {
                        SoundEngine.shared.play(.coin)
                        store.act { _ = $0.bookShow() }
                        store.closeShowCard()
                    }
                    .buttonStyle(ChunkyButtonStyle(kind: .big, wide: true))
                }
                Button {
                    SoundEngine.shared.play(.click)
                    store.closeShowCard()
                } label: { Text(loc("home.close")).frame(maxWidth: .infinity) }
                .buttonStyle(ChunkyButtonStyle(kind: st == .ok ? .ghost : .big, wide: true))
            }
        }
    }

    /// Why the show can't be booked now; also the short status on the entry rows.
    static func why(_ st: ShowState, _ g: Game) -> String {
        switch st {
        case .locked: loc("show.locked")
        case .booked: loc("show.booked")
        case .wait(let d): loc("show.wait", num(d))
        case .few: loc("show.few", num(Rules.showMinBalloons), num(g.showFleet.count))
        case .cash: loc("show.cash", eur(g.showCost))
        case .ok: loc("show.ready", num(g.showFleet.count), eur(g.showCost))
        }
    }

    /// Whether the show is worth a row on the pages: the market is open and the fleet is big enough.
    static func offered(_ g: Game) -> Bool { g.state.unlocked.contains(.market) && g.state.balloons.count >= Rules.showMinBalloons }
}
